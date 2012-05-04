json    = require 'lang/json'
type    = require 'lang/type'
func    = require 'lang/func'
string  = require 'lang/string'
cookies = require 'util/cookies'
Dir     = require 'io/Dir'
File    = require 'io/File'
xhr     = require 'io/xhr'
Job     = require 'download/Job'
Logger  = require 'Logger'
inspect = require 'util/inspect'
Server  = require 'io/http/Server'

{EventEmitter} = require 'events2'
{tryCatch, tryThrow} = require 'util/try'

class Controller
  constructor: ->
    @jobs = []

  start: (port) ->
    @windows ||= length: 1
    @windows[window.name] = window

    bindSuccessful = false

    listener = (request, response) =>
      @dispatch request, response

    tryCatch 'Controller#start', (log) =>
      @server = new Server port
      @port   = @server.port

    if not @server?
      return false

    @server.post '/_legacy', =>
      action = @server.request.json?.action.replace /\./g, '_'
      if type.isFunction @[action]
        logger.debug "Procesing legacy action #{inspect action}"
        @[action]? @server.request.json.body, (resdata) =>
          @server.deliver resdata
      else
        message = "Unrecognized legacy action #{inspect action}"
        logger.error message
        throw new Server.NotFoundError message


    ## POST /eval
    #
    #   Allows running arbitrary JS/CoffeeScript. Useful for facilitating
    #   building a REPL to introspect/debug at runtime.
    #
    #   script - a String of code to run
    #   type   - a String representing the MIME type of script
    #            (default: text/javascript)
    #   color  - a Boolean that, if true, makes the response string use ANSI
    #            color escapes (default: false)
    #
    #   Examples
    #
    #     # Request
    #     POST /eval HTTP/1.0
    #     Content-Type: application/json
    #
    #     {"script": "(-> 3+4)()", "type": "text/coffeescript"}
    #
    #
    #     # Response
    #     HTTP/1.0 200 OK
    #     Content-Type: application/json
    #
    #     {"result": "7"}
    #
    # Returns a REPL-friendly stringified version of the result.
    @server.post '/eval', =>
      params = @server.request.json
      script = params.script
      @scope ||=
        logger: Logger.loggerForFile('repl'),
        __filename: 'repl',
        __dirname: '.'
      @scope.job = @job

      if params.type is 'text/coffeescript'
        script = string.trim(CoffeeScript.compile "(-> #{script})()", bare: on)
      else
        script = "(function(){#{script}})()" if /[;\n]/.test script

      script = "return #{script}"
      result = func.callWithScope script, @scope, @scope

      @scope._ = result

      @server.deliver {result: inspect(result, undefined, undefined, color: params.color)}


    ## /jobs

    jobResponse = (job) ->
      return unless job?

      id: job.id
      status: job.status
      result: job.result
      data: job.data
      fid: job.fid
      completed: job.done
      cookies: cookies.dump()
      timestamp: new Date().getTime()
      version: job.version

    jobById = =>
      return job for job in @jobs when @server.params.id is job.id

    ## POST /jobs
    #
    #   Creates and starts a new sync job.
    #
    #   id      - an id to use to identify this job (optional)
    #   fid     - the reverse-dns of the player to use for this job
    #   creds   - an Object of credentials to use in this job
    #   options - an Object with customizations to how to run this job
    #             (default: {})
    #
    #   Examples
    #
    #     # Request
    #     POST /jobs HTTP/1.0
    #     Content-Type: application/json
    #
    #     {"fid": "com.example", "creds": {"username": "milo123", "password": "letmein"}}
    #
    #
    #     # Response
    #     HTTP/1.0 201 Created
    #     Content-Type: application/json
    #     Location: /jobs/1D992147-9078-0001-FFFF-1FFF1FFF1FFF
    #
    #   Returns a pointer to the newly created job in the form of a Location
    #   header URL.
    @server.post '/jobs', =>
      params = @server.request.json
      @jobs.push @job = new Job params.id, params.fid, params.creds, params.options
      cookies.restore params.cookies if params.cookies
      @job.start()
      @server.response.headers['Location'] = "/jobs/#{@job.id}"
      @server.deliver jobResponse(@job), status: 201

    ## GET /jobs
    #
    #   Lists all previously-run and currently running jobs.
    #
    #   Examples
    #
    #     # Request
    #     GET /jobs HTTP/1.0
    #
    #
    #     # Response
    #     HTTP/1.0 200 OK
    #     Content-Type: application/json
    #
    #     [{"id": "1D992147-9078-0001-FFFF-1FFF1FFF1FFF", "fid": "com.example", ...}]
    #
    #   Returns relevant data for all jobs started by this instance.
    @server.get '/jobs', =>
      @server.deliver(@jobs.map jobResponse)

    ## GET /jobs/:id
    #
    #   Gets data for a specific job by id.
    #
    #   Examples
    #
    #     # Request for a non-existent job id
    #     GET /jobs/1D992147-9078-0001-FFFF-1FFF1FFF1FFF HTTP/1.0
    #
    #     # Response
    #     HTTP/1.0 404 Not Found
    #
    #
    #     # Request for a real job id
    #     GET /jobs/1D992147-9078-0001-FFFF-1FFF1FFF1FFF HTTP/1.0
    #
    #     # Response
    #     HTTP/1.0 200 OK
    #     Content-Type: application/json
    #
    #     {"id": "1D992147-9078-0001-FFFF-1FFF1FFF1FFF", "fid": "com.example", ...}
    #
    #   Returns relevant data for the job given by id, or 404 Not Found if no
    #   such job exists.
    @server.get '/jobs/:id', =>
      @server.deliver(jobResponse jobById())

    ## PUT /jobs/:id
    #
    #   Updates the credentials for this job and resumes it.
    #
    #   Examples
    #
    #     # Request for a job that doesn't exist
    #     PUT /jobs/1D992147-9078-0001-FFFF-1FFF1FFF1FFF HTTP/1.0
    #     Content-Type: application/json
    #
    #     {"creds": [{"key": "What's your mother's maiden name?", "value": "Smith"}]}
    #
    #     # Response
    #     HTTP/1.0 404 Not Found
    #
    #
    #     # Request for a real job
    #     PUT /jobs/1D992147-9078-0001-FFFF-1FFF1FFF1FFF HTTP/1.0
    #     Content-Type: application/json
    #
    #     {"creds": [{"key": "What's your mother's maiden name?", "value": "Smith"}]}
    #
    #     # Response
    #     HTTP/1.0 200 OK
    #     Content-Type: application/json
    #
    #     {"id": "1D992147-9078-0001-FFFF-1FFF1FFF1FFF", "fid": "com.example", ...}
    #
    #   Returns relevant data for the job given by id, or 404 Not Found if no
    #   such job exists.
    @server.put '/jobs/:id', =>
      params = @server.request.json
      job = jobById()
      job?.resume? params.creds
      @server.deliver(jobResponse job)

    ## DELETE /jobs/:id
    #
    #   Stops the job with the given id but does not actually remove it from
    #   the list returned by GET /jobs.
    #
    #   Examples
    #
    #     # Request for a job that doesn't exist
    #     DELETE /jobs/1D992147-9078-0001-FFFF-1FFF1FFF1FFF HTTP/1.0
    #
    #     # Response
    #     HTTP/1.0 404 Not Found
    #
    #
    #     # Request for a real job
    #     DELETE /jobs/1D992147-9078-0001-FFFF-1FFF1FFF1FFF HTTP/1.0
    #
    #     # Response
    #     HTTP/1.0 200 OK
    #     Content-Type: application/json
    #
    #     {"id": "1D992147-9078-0001-FFFF-1FFF1FFF1FFF", "fid": "com.example", ...}
    #
    #   Returns relevant data for the stopped job or 404 Not Found if no such
    #   job exists.
    @server.delete '/jobs/:id', =>
      job = jobById()
      job.fail 504, 'timeout.quit' if job? and job.done is false
      @server.deliver(jobResponse job)


    ## /statements

    statementsDirectory = Dir.profile.child 'statements'

    readStatement = (id) ->
      statement = statementsDirectory.child(id)
      if statement.exists
        statement.read()
      else
        null

    getStatementList = ->
      if statementsDirectory.exists
        {id: file.basename} for file in statementsDirectory.children()
      else
        []

    ## GET /statements
    #
    #   Returns a list of all the statements downloaded for any jobs.
    #
    #   Examples
    #
    #     # Request
    #     GET /statements HTTP/1.0
    #
    #
    #     # Response
    #     HTTP/1.0 200 OK
    #     Content-Type: application/json
    #
    #     [{"id": "1D992147-9078-0001-FFFF-1FFF1FFF1FFF"}]
    #
    #   Returns relevant data for all jobs started by this instance.
    @server.get '/statements', =>
      @server.deliver(getStatementList())

    ## GET /statements/:id
    #
    #   Gets data for a specific statement by id.
    #
    #   Examples
    #
    #     # Request for a non-existent statement id
    #     GET /statements/1D992147-9078-0001-FFFF-1FFF1FFF1FFF HTTP/1.0
    #
    #     # Response
    #     HTTP/1.0 404 Not Found
    #
    #
    #     # Request for a real statement id
    #     GET /statements/1D992147-9078-0001-FFFF-1FFF1FFF1FFF HTTP/1.0
    #     Accept: application/ofx
    #
    #     # Response
    #     HTTP/1.0 200 OK
    #     Content-Type: application/ofx
    #
    #     OFXHEADER:100
    #     DATA:OFXSGML
    #     VERSION:102
    #     SECURITY:NONE
    #     ENCODING:USASCII
    #     ...
    #
    #     <OFX>
    #     ...
    #
    #   Returns relevant data for the job given by id, or 404 Not Found if no
    #   such job exists.
    @server.get '/statements/:id', =>
      @server.deliver(readStatement(@server.params.id), contentType: 'application/ofx')

    return true

  window_open: (data, respond) ->
    index = @windows.length++
    name = data?.name or "#{window.name}:#{index}"
    @windows[name] = window.open window.location.href, name, "chrome,width=600,height=300"

    waitForPort = =>
      if port = @windows[name].port
        respond response:
                  status: 'ok'
                  'window.open': {name, port}
      else
        setTimeout waitForPort, 10

    waitForPort()

  window_close: (name, respond) ->
    w = @windows[name]

    if w?
      w.close()
      delete @windows[name]

    respond response:
              status: 'ok'
              'window.close': w?

  window_list: (data, respond) ->
    respond response:
              status: 'ok'
              'window.list': ({name, port: w.port} for name, w of @windows when name isnt 'length')

  statement_list: (data, respond) ->
    statements = Dir.profile.child 'statements'
    list = []

    if statements.exists
      list = for file in statements.children()
               file.basename

    respond response:
              status: 'ok'
              'statement.list': list

  statement_read: (data, respond) ->
    unless data
      respond response:
                status: 'error'
                error: "statement id required"
      return

    statement = Dir.profile.child('statements').child(data)

    if statement.exists()
      respond response:
                status: 'ok'
                'statement.read': statement.read()
    else
      respond response:
                status: 'error'
                error: "No statement found with id=#{data}"

  job_stop: (data, respond) ->
    logger.info 'Got request to stop job, shutting down'

    # job didn't finish, so it failed
    @job.fail 504, 'timeout.quit' unless @job.done

    respond response:
              status: 'ok'

  xul_quit: (data, respond) ->
    setTimeout (-> goQuitApplication()), 1000

    respond response:
              status: 'ok'

  page_dump: (data, respond) ->
    try
      respond response:
                status: 'ok'
                'page.dump': @job.player.page.dump()

    catch e
      logger.error 'page.dump: ', e
      respond response:
                status: 'error'
                error: e.toString()

module.exports = Controller
