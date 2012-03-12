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
  start: (@port) ->
    @windows ||= length: 1
    @windows[window.name] = window

    bindSuccessful = false

    if @port
      # bind only to a specific port
      retriesLeft = 1
    else
      # start at 5000 and try up to 5100
      retriesLeft = 100
      @port = 5000

    listener = (request, response) =>
      @dispatch request, response

    tryCatch 'Controller#start', (log) =>
      @server = new Server()
      until bindSuccessful or retriesLeft is 0
        try
          @server.listen @port, listener
          bindSuccessful = true
          window.port = @port
        catch e
          log.warn 'Failed to bind to port ', @port, ', trying up to ', retriesLeft, ' more. ', e
          @port++
          retriesLeft--

      if bindSuccessful
        log.info 'Listening on port ', @port
        return true
      else
        log.error "Failed to start listener"
        return false

  dispatch: (request, response) ->
    data = ->
      result = json.parse request.body
      data = -> result
      data()

    try
      switch "#{request.method} #{request.url}"
        when 'POST /_legacy'
          @dispatchLegacy data(), (res) =>
            responseText = "#{json.render res}\n"
            response.headers['Content-Type'] = 'application/json'
            response.write responseText
            response.close()
        else
          response.statusCode = 404
          response.write "<html><head><title>404 Not Found</title></head><body><h1>404 Not Found</h1></body></html>\r\n"
          response.close()

    catch e
      logger.error "Error while processing request=", request, ": ", e
      response.statusCode = 500
      response.write "#{e}"
      response.close()


  dispatchLegacy: (request, respond) ->
    request.action = request.action.replace /\./g, '_'
    tryCatch 'Controller#dispatch', (log) =>
      if type.isFunction @[request.action]
        @[request.action]?(request.body, respond)
      else
        message = "Unrecognized request action #{inspect request.action}"
        log.error message

        respond response:
                  status: 'error'
                  error: message

  job_start: (data, respond) ->
    try
      throw new Error "Got unexpected type: #{typeof data}" if typeof data isnt 'object'

      @job = new Job data.jobid, data.fid, data.creds, data.user_id, data.options

      cookies.restore data.cookies if data.cookies

      if data.callback
        callbacks = if type.isString data.callback
                      [data.callback]
                    else
                      data.callback

        if callbacks.length
          @job.on 'update', =>
            params =
              status: @job.status
              result: @job.result
              data: json.render @job.data
              completed: @job.done
              cookies: cookies.dump()
              timestamp: new Date().getTime()
              version: @job.version

            for callback in callbacks
              xhr.put callback, params

      @job.start()
    catch e
      logger.error 'job.start: ', e

    respond response:
              status: 'ok'

  job_resume: (data, respond) ->
    if @job
      try
        @job.resume data.creds
        respond response:
                  status: 'ok'

      catch e
        respond response:
                  status: 'error'
                  error: e.toString()

    else
      respond response:
                status: 'error'
                error: "No running jobs"

  job_status: (data, respond) ->
    unless @job
      respond response:
                status: 'error'
                error: "No running jobs"
    else
      respond response:
                status: 'ok'
                'job.status':
                  status: @job.status
                  result: @job.result
                  data: @job.data
                  jobid: @job.jobid
                  fid: @job.fid
                  completed: @job.done
                  cookies: cookies.dump()
                  timestamp: new Date().getTime()
                  version: @job.version

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

  eval: (data, respond) ->
    try
      script = data.script
      @scope ||=
        logger: Logger.loggerForFile('repl'),
        __filename: 'repl',
        __dirname: '.'
      @scope.job = @job

      if data.type is 'text/coffeescript'
        script = string.trim(CoffeeScript.compile "(-> #{script})()", bare: on)
      else
        script = "(function(){#{script}})()" if /[;\n]/.test script

      script = "return #{script}"
      result = func.callWithScope script, @scope, @scope

      @scope._ = result

      respond response:
                status: 'ok'
                eval: inspect(result, undefined, undefined, color: data.color)

    catch e
      logger.error 'eval: error: ', e
      respond response:
                status: 'error'
                error: e.toString()


module.exports = Controller
