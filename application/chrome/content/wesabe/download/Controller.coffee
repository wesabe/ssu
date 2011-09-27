json    = require 'lang/json'
type    = require 'lang/type'
func    = require 'lang/func'
cookies = require 'util/cookies'
event   = require 'util/event'
dir     = require 'io/dir'
file    = require 'io/file'
xhr     = require 'io/xhr'
Job     = require 'download/Job'
Logger  = require 'Logger'
inspect = require 'util/inspect'
{tryCatch, tryThrow} = require 'util/try'

class Controller
  createServerSocket: ->
    Components.classes['@mozilla.org/network/server-socket;1']
      .createInstance(Components.interfaces.nsIServerSocket)

  start: (@port) ->
    bindSuccessful = false

    if @port
      # bind only to a specific port
      retriesLeft = 0
    else
      # start at 5000 and try up to 5100
      retriesLeft = 100
      @port = 5000

    tryCatch 'Controller#start', (log) =>
      @server = @createServerSocket()
      until bindSuccessful or retriesLeft is 0
        try
          @server.init @port, true, -1
          @server.asyncListen this
          bindSuccessful = true
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

  onSocketAccepted: (serv, transport) ->
    tryCatch 'Controller#onSocketAccepted', (log) =>
      outstream = transport.openOutputStream(Ci.nsITransport.OPEN_BLOCKING, 0, 0)

      stream = transport.openInputStream(0, 0, 0)
      instream = Cc['@mozilla.org/scriptableinputstream;1'].createInstance(Ci.nsIScriptableInputStream)

      instream.init stream
      log.debug 'Accepted connection'

      pump = Components.classes['@mozilla.org/network/input-stream-pump;1']
               .createInstance(Components.interfaces.nsIInputStreamPump)
      pump.init(stream, -1, -1, 0, 0, false)
      pump.asyncRead({
        onStartRequest: (request, context) =>
          log.radioactive this
          @request = ''

        onStopRequest: (request, context, status) =>
          log.radioactive this
          outstream.close()

        onDataAvailable: (request, context, inputStream, offset, count) =>
          data = instream.read count
          log.radioactive 'getting data: ', data
          @request += data

          while (index = @request.indexOf("\n")) isnt -1
            requestText = @request[0...index]
            @request = @request[index+1..]

            request      = json.parse requestText
            response     = @dispatch request
            try
              responseText = "#{json.render response}\n"
              log.radioactive responseText
              outstream.write responseText, responseText.length
            catch e
              log.error e
      }, null)

  onStopListening: (serv, status) ->
    logger.debug "Controller#onStopListening"

  dispatch: (request) ->
    request.action = request.action.replace /\./g, '_'
    tryCatch 'Controller#dispatch', (log) =>
      if type.isFunction @[request.action]
        @[request.action]?(request.body)
      else
        message = "Unrecognized request action #{inspect request.action}"
        log.error message

        response:
          status: 'error'
          error: message

  job_start: (data) ->
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
          event.add @job, 'update', =>
            params =
              status: @job.status
              result: @job.result
              data: json.render job.data
              completed: @job.done
              cookies: cookies.dump()
              timestamp: new Date().getTime()
              version: @job.version

            for callback in callbacks
              xhr.put callback, params

      @job.start()
    catch e
      logger.error 'job.start: ', e

    return response:
             status: 'ok'

  job_resume: (data) ->
    if @job
      try
        @job.resume data.creds
        return response:
                 status: 'ok'

      catch e
        return response:
                 status: 'error'
                 error: e.toString()

    else
      return response:
               status: 'error'
               error: "No running jobs"

  job_status: (data) ->
    unless @job
      return response:
               status: 'error'
               error: "No running jobs"

    response:
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

  statement_list: (data) ->
    statements = dir.profile
    statements.append 'statements'
    list = []

    if statements.exists()
      list = for {path} in dir.read statements
               path.match(/\/([^\/]+)$/)[1]

    response:
      status: 'ok'
      'statement.list': list

  statement_read: (data) ->
    unless data
      return response:
               status: 'error'
               error: "statement id required"

    statement = dir.profile
    statement.append 'statements'
    statement.append data

    if statement.exists()
      response:
        status: 'ok'
        'statement.read': file.read statement
    else
      response:
        status: 'error'
        error: "No statement found with id=#{data}"

  job_stop: (data) ->
    logger.info 'Got request to stop job, shutting down'

    # job didn't finish, so it failed
    job.fail 504, 'timeout.quit' unless @job.done

    response:
      status: 'ok'

  xul_quit: (data) ->
    setTimeout (-> goQuitApplication()), 1000

    response:
      status: 'ok'

  page_dump: (data) ->
    try
      response:
        status: 'ok'
        'page.dump': @job.player.page.dump()

    catch e
      logger.error 'page.dump: ', e
      response:
        status: 'error'
        error: e.toString()

  eval: (data) ->
    try
      script = data.script
      @scope ||= {@job, logger}

      if data.type is 'text/coffeescript'
        script = CoffeeScript.compile "return (-> #{script})()"
      else
        script = "(function(){#{script}})()" if /[;\n]/.test script

      script = "return #{script}"
      logger = Logger.loggerForFile 'repl'
      result = func.callWithScope script, wesabe, scope

      scope._ = result

      response:
        status: 'ok'
        eval: inspect(result, undefined, undefined, color: data.color)

    catch e
      logger.error 'eval: error: ', e
      response:
        status: 'error'
        error: e.toString()


module.exports = Controller
