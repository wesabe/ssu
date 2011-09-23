wesabe.provide 'fi-scripts'
wesabe.require 'logger.*'
wesabe.require 'dom.*'
wesabe.require 'xul.UserAgent'

wesabe.provide 'download.Player', class Player
  @register: (params) ->
    @create params, (klass) ->
      # make sure we put it where wesabe.require expects it
      wesabe.provide "fi-scripts.#{params.fid}", klass

  @create: (params, callback) ->
    class klass extends wesabe.download.Player
      # the Wesabe Financial Institution ID (e.g. com.Chase)
      @fid: params.fid

      # the name of the Financial Institution (e.g. Chase)
      @org: params.org

      # ofx info in case this is a hybrid
      @ofx: params.ofx

      # the elements we need to recognize
      @elements: {}

      # pass .fid and .org through to the class
      @::__defineGetter__ 'fid', -> @constructor.fid
      @::__defineGetter__ 'org', -> @constructor.org

      canHandleGoal: params.canHandleGoal or (-> true)

    callback?(klass)

    params.__module__ = klass.__module__

    # the method that decides based on the state of the job and page what to do next
    klass::dispatches = []
    # any dispatch filters
    klass::filters = []
    # any download callbacks
    klass::afterDownloadCallbacks = []
    # after last goal callbacks
    klass::afterLastGoalCallbacks = []
    # any alert callbacks
    klass::alertReceivedCallbacks = []
    # any confirm callbacks
    klass::confirmReceivedCallbacks = []
    # any open callbacks
    klass::openReceivedCallbacks = []

    modules = [params]

    if params.includes
      for include in params.includes
        try
          modules.push(wesabe.require(include));
        catch ex
          throw new Error("Error while requiring #{include} -- check that the file exists and has the correct 'provide' line")

    # dispatchFrames: false
    if params.dispatchFrames is false
      klass::filters.push
        name: 'frame blocker'
        test: ->
          if page.defaultView.frameElement
            wesabe.info "skipping frame page load: ", page.title
            return false

    if params.filter
      klass::filters.push
        name: 'global'
        test: params.filter

    # userAgent: "Mozilla/4.0 HappyFunBrowser"
    if params.userAgent
      klass::userAgent = params.userAgent

    # userAgentAlias: "Firefox"
    if params.userAgentAlias
      klass::userAgent = wesabe.xul.UserAgent.getByNamedAlias(params.userAgentAlias)

    for module in modules
      if module.dispatch
        klass::dispatches.push
          name: module.__module__.name
          callback: module.dispatch

      if module.elements
        wesabe.lang.extend klass.elements, module.elements, merge: true

      if module.actions
        wesabe.lang.extend klass::, module.actions

      if module.extensions
        wesabe.lang.extend klass::, module.extensions

      if module.afterDownload
        klass::afterDownloadCallbacks.push module.afterDownload

      if module.afterLastGoal
        klass::afterLastGoalCallbacks.push module.afterLastGoal

      if module.alertReceived
        klass::alertReceivedCallbacks.push module.alertReceived

      if module.confirmReceived
        klass::confirmReceivedCallbacks.push module.confirmReceived

      if module.openReceived
        klass::openReceivedCallbacks.push module.openReceived

      if module.filter
        klass::filters.push
          name: module.__module__.name
          test: module.filter

    return klass

  start: (answers, browser) ->
    if @userAgent
      wesabe.xul.UserAgent.set @userAgent
    else
      wesabe.xul.UserAgent.revertToDefault()

    # set up the callbacks for page load and download done
    wesabe.bind browser, 'DOMContentLoaded', (event) =>
      @onDocumentLoaded browser, wesabe.dom.page.wrap(event.target)

    wesabe.bind 'downloadSuccess', (event, data, filename) =>
      @job.update 'account.download.success'
      @setErrorTimeout 'global'

      wesabe.tryThrow 'Player#downloadSuccess', (log) =>
        folder = wesabe.io.dir.profile
        folder.append 'statements'
        unless folder.exists()
          wesabe.io.dir.create(folder)

        statement = folder.clone()
        statement.append new wesabe.ofx.UUID().toString()

        wesabe.io.file.write statement, data

        @job.recordSuccessfulDownload statement, filename, @job.nextDownloadMetadata
        delete @job.nextDownloadMetadata
        @onDownloadSuccessful @browser, @page

    wesabe.bind 'downloadFail', (event) =>
      wesabe.warn 'Failed to download a statement! This is bad, but a failed job is worse, so we press on'
      @job.update 'account.download.failure'
      @setErrorTimeout 'global'
      @onDownloadSuccessful @browser, @page

    @setErrorTimeout 'global'
    # start the security question timeout when the job is suspended
    wesabe.bind @job, 'suspend', =>
      @clearErrorTimeout 'action'
      @clearErrorTimeout 'global'
      @setErrorTimeout 'security'

    wesabe.bind @job, 'resume', =>
      @clearErrorTimeout 'security'
      @setErrorTimeout 'global'

    @answers = answers
    @runAction 'main', browser

  nextGoal: ->
    @job.nextGoal()

  onLastGoalFinished: ->
    wesabe.info 'Finished all goals, running callbacks'
    for callback in @afterLastGoalCallbacks
      @runAction callback, @browser, @page

  finish: ->
    @clearErrorTimeout 'action'
    @clearErrorTimeout 'global'
    @clearErrorTimeout 'security'

  runAction: (name, browser, page, scope) ->
    module = @constructor.fid

    fn = if wesabe.isFunction(name) then name else @[name]
    name = if wesabe.isFunction(name) then (name.name or '(anonymous)') else name

    @job.timer.end 'Navigate'

    unless fn
      throw new Error "Cannot find action '#{name}'! Typo? Forgot to include a file?"

    retval = wesabe.tryThrow "#{module}##{name}", (log) =>
      url = page and wesabe.taint(page.defaultView.location.href)
      title = page && wesabe.taint(page.title)

      @job.timer.start 'Action', =>
        @setErrorTimeout 'action'
        @history.push
          name: name
          url: url
          title: title

        wesabe.info 'History is ', (hi.name for hi in @history).join(' -> ')

        wesabe.lang.func.callWithScope fn, this, wesabe.lang.extend(
          browser: browser
          page: page
          e: @constructor.elements
          answers: @answers
          options: @job.options
          log: log
          tmp: @tmp
          action: @getActionProxy(browser, page)
          job: @getJobProxy()
          skipAccount: @skipAccount
          reload: => @triggerDispatch(browser, page)
          download: (args...) => @download(args...)
        , scope or {})

    @job.timer.start 'Navigate', overlap: false

    return retval

  resume: (answers) ->
    if wesabe.isArray(answers)
      for {key, value} in answers
        @answers[key] = value
    else if wesabe.isObject(answers)
      # TODO: 2008-11-24 <brian@wesabe.com> -- this is only here until the new style (Array) is in PFC and SSU Service
      wesabe.lang.extend @answers, answers

    @onDocumentLoaded @browser, @page

  getActionProxy: (browser, page) ->
    new ActionProxy this, browser, page

  getJobProxy: ->
    @job

  download: (url, metadata) ->
    # hang on to the current browser and page so we can reload with the right context
    browser = @browser
    page = @page

    newStatementFile = =>
      folder = wesabe.io.dir.profile
      folder.append 'statements'
      wesabe.io.dir.create(folder) unless folder.exists()

      statement = folder.clone()
      statement.append new wesabe.ofx.UUID().toString()

      return statement


    # allow pre-registering information about the next download
    if wesabe.isFunction(metadata)
      callback = metadata
      metadata = url
      url = null

      @job.nextDownloadMetadata = metadata
      callback()

      return
    else if metadata is undefined
      metadata = url
      url = null

      unless metadata.data
        throw new Error "Expected metadata #{metadata} to have data to write"

      file = newStatementFile()
      wesabe.io.file.write file, metadata.data
      delete metadata.data
      @job.recordSuccessfulDownload file, metadata.suggestedFilename, metadata
      @onDownloadSuccessful browser, page

      return

    metadata = wesabe.lang.extend url: url, (metadata or {})

    wesabe.tryThrow "Player#download(#{url})", (log) =>
      wesabe.io.download url, newStatementFile(),
        success: (file, suggestedFilename) =>
          @job.recordSuccessfulDownload file, suggestedFilename, metadata
          @onDownloadSuccessful browser, page

        failure: =>
          @job.recordFailedDownload metadata
          @onDownloadSuccessful browser, page


  #
  # Answers whatever security questions are on the page by
  # using the xpaths given in e.security.
  #
  answerSecurityQuestions: ->

    questions = page.select e.security.questions
    qanswers  = page.select e.security.answers

    if questions.length isnt qanswers.length
      wesabe.error "Found ", questions.length, " security questions, but ",
        qanswers.length, " security question answers to fill"
      wesabe.error "questions = ", questions
      wesabe.error "qanswers = ", qanswers
      return false

    if questions.length is 0
      wesabe.error "Failed to find any security questions"
      return false

    questions = (wesabe.lang.string.trim(page.text(q)) for q in questions)

    wesabe.info "Found security questions: ", questions
    questions = wesabe.untaint questions

    data = questions: []
    for question, i in questions
      answer   = answers[question]
      element  = qanswers[i]

      if answer
        page.fill element, answer
      else
        log.debug "element = ", element, " -- element.type = ", element.type
        data.questions.push
          key: question
          label: question
          persistent: true
          type: wesabe.untaint(element.type) or "text"

    if data.questions.length
      job.suspend 'suspended.missing-answer.auth.security', data
      return false

    job.update 'auth.security'

    # choose to bypass the security questions if we can
    page.check e.security.setCookieCheckbox if e.security.setCookieCheckbox
    page.fill e.security.setCookieSelect, e.security.setCookieOption if e.security.setCookieSelect
    # submit the form
    page.click e.security.continueButton

    return true

  #
  # Fills in the date range for a download based on a lower bound.
  #
  # ==== Options (options)
  # :since<Number, null>::
  #   Time of the lower bound to use for the date range (in ms since epoch).
  #
  # @public
  #
  fillDateRange: ->
    formatString = e.download.date.format or 'MM/dd/yyyy'

    opts   = e.download.date
    fromEl = wesabe.untaint page.find(opts.from)
    toEl   = wesabe.untaint page.find(opts.to)

    getDefault = (defaultValue, existing) =>
      if wesabe.isFunction(defaultValue)
        defaultValue = defaultValue(existing)

      wesabe.lang.date.parse(defaultValue) if defaultValue

    if toEl
      to = wesabe.dom.date.forElement(toEl, formatString)
      # use default or today's date if we can't get a date from the field
      to.date ||= getDefault(opts.defaults && opts.defaults.to) or new Date()

      log.info "Adjusting date upper bound: ", to.date

    if fromEl
      # if there's a lower bound, choose a week before it to ensure some overlap
      since = options.since and (options.since - 7 * wesabe.lang.date.DAYS)

      # get a date if there's already one in the field
      from = wesabe.dom.date.forElement fromEl, formatString

      if from.date and since
        # choose the most recent of the pre-populated date and the lower bound
        from.date = new Date(Math.max(since, from.date.getTime()))
      else if since
        # choose the lower bound
        from.date = new Date(since)
      else if to
        # pick the default or an 89 day window
        from.date = getDefault(opts.defaults and opts.defaults.from, to: to.date) or
          wesabe.lang.date.add(to.date, -89 * wesabe.lang.date.DAYS)

      log.info "Adjusting date lower bound: ", from.date


  nextAccount: ->
    delete tmp.account
    reload()


  skipAccount: (args...) ->
    wesabe.warn(args...) if args.length
    delete @tmp.account

  actionTimeoutDuration: 60000 # 1m
  globalTimeoutDuration: 300000 # 5m
  securityTimeoutDuration: 180000 # 3m

  setErrorTimeout: (type) ->
    duration = @["#{type}TimeoutDuration"]
    tt = @_timeouts
    tt ||= @_timeouts = {}

    @clearErrorTimeout type

    wesabe.debug "Timeout ", type, " set (",duration,")"

    tt[type] = setTimeout =>
      wesabe.trigger this, 'timeout', [type]
      return if @job.done
      wesabe.error "Timeout ",type," (",duration,") reached, abandoning job"
      wesabe.tryCatch "Player#setErrorTimeout(page dump)", =>
        @page?.dumpPrivately()
      @job.fail 504, "timeout.#{type}"
    , duration

  clearErrorTimeout: (type) ->
    if @_timeouts?[type]
      wesabe.debug "Timeout ", type, " cleared"
      clearTimeout @_timeouts[type]

  onDocumentLoaded: (browser, page) ->
    return if @job.done or @job.paused

    module = @constructor.fid

    # log when alert and confirm are called
    new wesabe.dom.Bridge page.proxyTarget, ->
      @evaluate ->
        # evaluated on the page
        window.alert = (message) ->
          callback 'alert', message
          return true
        window.confirm = (message) ->
          callback 'confirm', message
          return true
        window.open = (url) ->
          callback 'open', url
          return false

      , (data) ->
        # evaluated here
          unless data
            wesabe.debug "Bridge connected"
            return

          [type, message] = data

          switch type
            when 'alert'
              wesabe.info type, ' called with message=', wesabe.util.inspectForLog(message)

            when 'confirm'
              wesabe.info type, ' called with message=', wesabe.util.inspectForLog(message), ', automatically answered YES'

            when 'open'
              wesabe.info type, ' called with url=', wesabe.util.inspectForLog(message)

          callbacks = @["#{type}ReceivedCallbacks"]
          if callbacks
            for callback in callbacks
              wesabe.lang.func.callWithScope callback, this,
                message: message
                browser: browser
                page: page
                e: @constructor.elements
                answers: @answers
                options: @job.options
                log: wesabe
                tmp: @tmp
                action: @getActionProxy browser, page
                job: @getJobProxy()
                reload: => @triggerDispatch browser, page
                skipAccount: @skipAccount
                download: (args...) => @download args...
              , [message]

    unless @shouldDispatch browser, page
      wesabe.info 'skipping document load'
      return

    @triggerDispatch browser, page

  triggerDispatch: (browser, page) ->
    module = @constructor.fid

    browser = browser or @browser
    page = page or @page

    url = wesabe.taint(page.defaultView.location.href)
    title = wesabe.taint(page.title)

    wesabe.info 'url=', url
    wesabe.info 'title=', title

    wesabe.trigger this, 'page-load', [browser, page]

    # these should not be used inside the FI scripts
    @browser = browser
    @page = page

    @job.timer.start 'Sleep', overlap: false

    setTimeout =>
      return if @job.done or @job.paused

      for dispatch in @dispatches
        result = wesabe.tryThrow "#{module}#dispatch(#{dispatch.name})", (log) =>
          @job.timer.start 'Dispatch', overlap: false

          wesabe.lang.func.callWithScope dispatch.callback, this,
            browser: browser
            page: page
            e: @constructor.elements
            answers: @answers
            options: @job.options
            log: log
            tmp: @tmp
            action: @getActionProxy browser, page
            job: @getJobProxy()
            reload: => @triggerDispatch browser, page
            skipAccount: @skipAccount
            download: (args...) => @download args...

        if result is false
          wesabe.info "dispatch chain halted"
          return
    , 2000

  onDownloadSuccessful: (browser, page) ->
    for callback in @afterDownloadCallbacks
      @runAction callback, browser, page

  shouldDispatch: (browser, page) ->
    for filter in @filters
      result = wesabe.tryCatch "#{@constructor.fid}#filter(#{filter.name})", (log) =>
        r = wesabe.lang.func.callWithScope filter.test, this,
          browser: browser
          page: page
          e: @constructor.elements
          log: log
          tmp: @tmp
          job: @getJobProxy()
          skipAccount: @skipAccount

        if r is true
          log.debug "forcing dispatch"
        else if r is false
          log.debug "aborting dispatch"

        return r

      # check for a definite answer
      return result if wesabe.isBoolean result

    wesabe.debug "no filter voted to force or abort dispatch, so forcing dispatch by default"
    return true

  @::__defineGetter__ 'history', ->
    @_history ||= []

  @::__defineGetter__ 'tmp', ->
    @_tmp ||= {}

  @build: (fid) ->
    wesabe.tryThrow "download.Player.build(fid=#{fid})", (log) =>
      klass = wesabe.tryThrow "loading fi-scripts.#{fid}", =>
        wesabe.require 'fi-scripts.' + fid

      new klass(fid)

class ActionProxy
  constructor: (@player, @browser, @page) ->

  __noSuchMethod__: (method, args) ->
    @player.runAction method, @browser, @page
