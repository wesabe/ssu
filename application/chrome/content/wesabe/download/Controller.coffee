wesabe.provide('download.Controller')
wesabe.require('download.Player')
wesabe.require('download.CompoundPlayer')
wesabe.require('canvas.snapshot')

class wesabe.download.Controller
  createServerSocket: ->
    Components.classes['@mozilla.org/network/server-socket;1']
      .createInstance(Components.interfaces.nsIServerSocket)

  start: (port) ->
    bindSuccessful = false

    if port
      # bind only to a specific port
      retriesLeft = 0
    else
      # start at 5000 and try up to 5100
      retriesLeft = 100
      port = 5000

    wesabe.tryCatch 'Controller#start', (log) =>
      @server = @createServerSocket()
      while !bindSuccessful && retriesLeft > 0
        try
          @server.init(port, true, -1)
          @server.asyncListen(this)
          bindSuccessful = true
        catch e
          log.warn('Failed to bind to port ', port, ', trying up to ', retriesLeft, ' more. ', e)
          port++
          retriesLeft--

      if bindSuccessful
        log.info('Listening on port ', port)
        return port
      else
        log.error("Failed to start listener")

  onSocketAccepted: (serv, transport) ->
    wesabe.tryCatch 'Controller#onSocketAccepted', (log) =>
      outstream = transport.openOutputStream(Components.interfaces.nsITransport.OPEN_BLOCKING, 0, 0)

      stream = transport.openInputStream(0, 0, 0)
      instream = Components.classes['@mozilla.org/scriptableinputstream;1']
                   .createInstance(Components.interfaces.nsIScriptableInputStream)

      instream.init(stream)
      log.debug('Accepted connection')

      pump = Components.classes['@mozilla.org/network/input-stream-pump;1']
               .createInstance(Components.interfaces.nsIInputStreamPump)
      pump.init(stream, -1, -1, 0, 0, false)
      pump.asyncRead({
        onStartRequest: (request, context) =>
          log.radioactive(this)
          @request = ''

        onStopRequest: (request, context, status) =>
          log.radioactive(this)
          outstream.close()

        onDataAvailable: (request, context, inputStream, offset, count) =>
          data = instream.read(count)
          log.radioactive('getting data: ', data)
          @request += data

          while (index = @request.indexOf("\n")) != -1
            requestText = @request.substring(0, index)
            @request = @request.substring(index+1);

            request      = wesabe.lang.json.parse(requestText)
            response     = @dispatch(request)
            try
              responseText = wesabe.lang.json.render(response)+"\n"
              log.radioactive(responseText)
              outstream.write(responseText, responseText.length)
            catch e
              wesabe.error(e)
      }, null)

  onStopListening: (serv, status) ->
    wesabe.debug("Controller#onStopListening")

  dispatch: (request) ->
    request.action = request.action.replace('.', '_')
    wesabe.tryCatch 'Controller#dispatch', (log) =>
      if wesabe.isFunction(this[request.action])
        return this[request.action].call(this, request.body)
      else
        message = "Unrecognized request action #{wesabe.util.inspect(request.action)}"
        log.error(message)
        return {response: {status: 'error', error: message}}

  job_start: (data) ->
    try
      throw new Error("Got unexpected type: #{typeof data}") if typeof data != 'object'

      @job = new wesabe.download.Job(data.jobid, data.fid, data.creds, data.user_id, data.options)

      wesabe.util.cookies.restore(data.cookies) if data.cookies

      if data.callback
        callbacks = if wesabe.isString(data.callback)
                      [data.callback]
                    else
                      data.callback

        if callbacks.length
          wesabe.bind @job, 'update', =>
            params =
              status: @job.status
              result: @job.result
              data: wesabe.lang.json.render(job.data)
              completed: @job.done
              cookies: wesabe.util.cookies.dump()
              timestamp: new Date().getTime()
              version: @job.version

            for callback in callbacks
              wesabe.io.put(callback, params)

      @job.start()
    catch e
      wesabe.error('job.start: ', e);

    return {response: {status: 'ok'}}

  job_resume: (data) ->
    if @job
      try
        @job.resume(data.creds)
        {response: {status: 'ok'}}
      catch e
        {response: {status: 'error', error: e.toString()}}
    else
      {response: {status: 'error', error: "No running jobs"}}

  job_status: (data) ->
    return {response: {status: 'error', error: "No running jobs"}} unless @job

    response:
      status: 'ok'
      'job.status':
        status: @job.status
        result: @job.result
        data: @job.data
        jobid: @job.jobid
        fid: @job.fid
        completed: @job.done
        cookies: wesabe.util.cookies.dump()
        timestamp: new Date().getTime()
        version: @job.version

  statement_list: (data) ->
    statements = wesabe.io.dir.profile
    statements.append('statements')
    list = []

    if statements.exists()
      list = for file in wesabe.io.dir.read(statements)
               file.path.match(/\/([^\/]+)$/)[1]

    response:
      status: 'ok', 'statement.list': list

  statement_read: (data) ->
    return {response: {status: 'error', error: "statement id required"}} unless data

    statement = wesabe.io.dir.profile
    statement.append('statements')
    statement.append(data)

    if statement.exists()
      response:
        status: 'ok'
        'statement.read': wesabe.io.file.read(statement)
    else
      response:
        status: 'error'
        error: "No statement found with id=#{data}"

  job_stop: (data) ->
    wesabe.info('Got request to stop job, shutting down')
    job.fail(504, 'timeout.quit') unless @job.done
    # job didn't finish, so it failed

    response:
      status: 'ok'

  xul_quit: (data) ->
    setTimeout((-> goQuitApplication()), 1000)

    response:
      status: 'ok'

  page_dump: (data) ->
    try
      response:
        status: 'ok'
        'page.dump': @job.player.page.dump()
    catch e
      wesabe.error('page.dump: ', e)
      response:
        status: 'error'
        error: e.toString()

  eval: (data) ->
    try
      script = data.script
      script = "(function(){#{script}})()" if /[;\n]/.test(script)
      script = "return #{script}"
      result = wesabe.lang.func.callWithScope(script, wesabe, {job: @job})

      response:
        status: 'ok'
        eval: wesabe.util.inspect(result)
    catch e
      wesabe.error('eval: error: ', e)
      response:
        status: 'error'
        error: e.toString()
