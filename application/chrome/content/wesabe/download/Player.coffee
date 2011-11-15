wesabe.provide 'fi-scripts'

extend         = require 'lang/extend'
date           = require 'lang/date'
array          = require 'lang/array'
dateForElement = (require 'dom/date').forElement
{trim}         = require 'lang/string'
func           = require 'lang/func'
type           = require 'lang/type'
event          = require 'util/event'
prefs          = require 'util/prefs'
inspect        = require 'util/inspect'
Dir            = require 'io/Dir'
File           = require 'io/File'
{download}     = require 'io/Downloader'
uuid           = (require 'ofx/UUID').string
privacy        = require 'util/privacy'
Page           = require 'dom/Page'
Browser        = require 'dom/Browser'
UserAgent      = require 'xul/UserAgent'
Bridge         = require 'dom/Bridge'
{Pathway}      = require 'xpath'

{tryThrow, tryCatch} = require 'util/try'

DEFAULT_TIMEOUTS =
  action:    60 # 1m
  global:   300 # 5m
  security: 180 # 3m

class Player
  @register: (params) ->
    @create params, (klass) ->
      # make sure we put it where wesabe.require expects it
      wesabe.provide "fi-scripts.#{params.fid}", klass

  @create: (params, callback) ->
    class klass extends Player
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
          modules.push wesabe.require(include)
        catch ex
          throw new Error "Error while requiring #{include} -- check that the file exists and has the correct 'provide' line"

    # dispatchFrames: off
    if params.dispatchFrames is off
      klass::filters.push
        name: 'frame blocker'
        test: (browser, page) ->
          if page.framed
            logger.info "skipping frame page load: ", page.title
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
      klass::userAgent = UserAgent.getByNamedAlias(params.userAgentAlias)

    for module in modules
      if module.dispatch
        klass::dispatches.push
          name: module.__module__.name
          callback: module.dispatch

      if module.elements
        extend klass.elements, module.elements, merge: on

      if module.actions
        extend klass::, module.actions

      if module.extensions
        extend klass::, module.extensions

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
      UserAgent.set @userAgent
    else
      UserAgent.revertToDefault()

    # set up the callbacks for page load and download done
    event.add browser, 'DOMContentLoaded', (evt) =>
      @onDocumentLoaded Browser.wrap(browser), Page.wrap(evt.target)

    event.add 'downloadSuccess', (evt, data, suggestedFilename, contentType) =>
      @job.update 'account.download.success'
      @setErrorTimeout 'global'

      tryThrow 'Player#downloadSuccess', (log) =>
        folder = Dir.profile.child('statements')
        unless folder.exists
          folder.create()

        statement = statements.child(uuid()).asFile

        statement.write data

        metadata = @job.nextDownloadMetadata or {}
        delete @job.nextDownloadMetadata

        # restore the browser and page the download was triggered from, if any
        if metadata.browser
          @browser = metadata.browser
          delete metadata.browser
        if metadata.page
          @page = metadata.page
          delete metadata.page

        @job.recordSuccessfulDownload statement, extend({suggestedFilename, contentType}, metadata)
        @onDownloadSuccessful @browser, @page

    event.add 'downloadFail', (evt) =>
      logger.warn 'Failed to download a statement! This is bad, but a failed job is worse, so we press on'
      @job.update 'account.download.failure'
      @setErrorTimeout 'global'
      @onDownloadSuccessful @browser, @page

    @setErrorTimeout 'global'
    # start the security question timeout when the job is suspended
    event.add @job, 'suspend', =>
      @clearErrorTimeout 'action'
      @clearErrorTimeout 'global'
      @setErrorTimeout 'security'

    event.add @job, 'resume', =>
      @clearErrorTimeout 'security'
      @setErrorTimeout 'global'

    @answers = answers
    @runAction 'main', Browser.wrap(browser)

  nextGoal: ->
    @job.nextGoal()

  onLastGoalFinished: ->
    logger.info 'Finished all goals, running callbacks'
    for callback in @afterLastGoalCallbacks
      @runAction callback, @browser, @page

  finish: ->
    @clearErrorTimeout 'action'
    @clearErrorTimeout 'global'
    @clearErrorTimeout 'security'

  runAction: (name, browser, page, scope) ->
    module = @constructor.fid

    [fn, name] = if type.isFunction name
                   [name, name.name or '(anonymous)']
                 else
                   [@[name], name]

    unless fn
      throw new Error "Cannot find action '#{name}'! Typo? Forgot to include a file?"

    retval = tryThrow "#{module}##{name}", (log) =>
      url = page?.url
      title = page?.title

      @setErrorTimeout 'action'
      @history.push
        name: name
        url: url
        title: title

      logger.info 'History is ', (hi.name for hi in @history).join(' -> ')

      @callWithAppropriateScope fn, browser, page, extend({log}, scope or {})

    return retval

  @::__defineGetter__ 'elements', ->
    @constructor.elements

  @::__defineGetter__ 'e', ->
    @elements

  resume: (answers) ->
    if type.isArray answers
      for {key, value} in answers
        @answers[key] = value

    else if type.isObject answers
      # TODO: 2008-11-24 <brian@wesabe.com> -- this is only here until the new style (Array) is in PFC and SSU Service
      extend @answers, answers

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
      folder = Dir.profile.child('statements')
      folder.create() unless folder.exists

      return folder.child(uuid())


    # allow pre-registering information about the next download
    if type.isFunction metadata
      callback = metadata
      metadata = url
      url = null

      metadata.browser = browser
      metadata.page = page

      @job.nextDownloadMetadata = metadata
      callback()

      return
    else if metadata is undefined
      metadata = url
      url = null

      unless metadata.data
        throw new Error "Expected metadata #{metadata} to have data to write"

      statement = newStatementFile()
      statement.write metadata.data
      delete metadata.data
      @job.recordSuccessfulDownload statement, metadata
      @onDownloadSuccessful browser, page

      return

    url = privacy.untaint url
    metadata = extend {url}, (metadata or {})

    tryThrow "Player#download(#{url})", =>
      download url, newStatementFile(),
        success: (path, suggestedFilename, contentType) =>
          @job.recordSuccessfulDownload path, extend({suggestedFilename, contentType}, metadata)
          @onDownloadSuccessful browser, page

        failure: =>
          @job.recordFailedDownload metadata
          @onDownloadSuccessful browser, page


  # Public: Answers whatever security questions are on the page by
  # using the xpaths given in e.security.
  #
  # NOTE: Called with magic scope!
  #
  answerSecurityQuestions: ->
    @answerSecurityQuestionsWithoutMagicScope browser ? @browser, page ? @page

  # Internal: Answers whatever security questions are on the page by
  # using the xpaths given in e.security.
  #
  # browser - The context Browser.
  # page - The context Page.
  answerSecurityQuestionsWithoutMagicScope: (browser, page) ->
    # these are here because this function is called with magic scope
    # and therefore won't see the variables we defined above
    questions = page.select @e.security.questions
    qanswers  = page.select @e.security.answers

    if questions.length isnt qanswers.length
      logger.error "Found ", questions.length, " security questions, but ",
        qanswers.length, " security question answers to fill"
      logger.error "questions = ", questions
      logger.error "qanswers = ", qanswers
      return false

    if questions.length is 0
      logger.error "Failed to find any security questions"
      return false

    questions = (trim page.text(q) for q in questions)

    logger.info "Found security questions: ", questions
    questions = privacy.untaint questions

    data = questions: []
    for question, i in questions
      answer   = @answers[question]
      element  = qanswers[i]

      if answer
        page.fill element, answer
      else
        logger.debug "element = ", element, " -- element.type = ", element.type
        data.questions.push
          key: question
          label: question
          persistent: true
          type: privacy.untaint(element.type) or "text"

    if data.questions.length
      @job.suspend 'suspended.missing-answer.auth.security', data
      return false

    @job.update 'auth.security'

    # choose to bypass the security questions if we can
    page.check @e.security.setCookieCheckbox if @e.security.setCookieCheckbox
    page.fill @e.security.setCookieSelect, @e.security.setCookieOption if @e.security.setCookieSelect
    # submit the form
    page.click @e.security.continueButton

    return true

  #
  # Fills in the date range for a download based on a lower bound.
  #
  # NOTE: This is an action and may be called with action.fillDateRange().
  # Be warned: because this is an action _it is called with magic scope_.
  #
  # ==== Options (options)
  # :since<Number, null>::
  #   Time of the lower bound to use for the date range (in ms since epoch).
  #
  # @public
  #
  fillDateRange: ->
    @fillDateRangeWithoutMagicScope @browser, @page

  # Internal: Fills out the date form fields for a download.
  fillDateRangeWithoutMagicScope: (browser, page) ->
    formatString = @elements.download.date.format or 'MM/dd/yyyy'

    opts   = @elements.download.date
    fromEl = privacy.untaint page.find(opts.from)
    toEl   = privacy.untaint page.find(opts.to)

    getDefault = (defaultValue, existing) =>
      if type.isFunction defaultValue
        defaultValue = defaultValue(existing)

      date.parse(defaultValue) if defaultValue

    if toEl
      to = dateForElement(toEl, formatString)
      # use default or today's date if we can't get a date from the field
      to.date ||= getDefault(opts.defaults && opts.defaults.to) or new Date()

      logger.info "Adjusting date upper bound: ", to.date

    if fromEl
      # if there's a lower bound, choose a week before it to ensure some overlap
      since = options.since and (options.since - 7 * date.DAYS)

      # get a date if there's already one in the field
      from = dateForElement fromEl, formatString

      if from.date and since
        # choose the most recent of the pre-populated date and the lower bound
        from.date = new Date Math.max(since, from.date.getTime())
      else if since
        # choose the lower bound
        from.date = new Date since
      else if to
        # pick the default or an 89 day window
        from.date = getDefault(opts.defaults and opts.defaults.from, to: to.date) or
          date.add(to.date, -89 * date.DAYS)

      logger.info "Adjusting date lower bound: ", from.date


  nextAccount: ->
    delete tmp.account
    reload()


  skipAccount: (args...) ->
    logger.warn args... if args.length
    delete @tmp.account

  setErrorTimeout: (timeoutType) ->
    duration = (prefs.get "wesabe.download.player.timeout.#{timeoutType}") or DEFAULT_TIMEOUTS[timeoutType]
    tt = @_timeouts
    tt ||= @_timeouts = {}

    @clearErrorTimeout timeoutType

    logger.debug "Timeout ", timeoutType, " set (", duration, " seconds)"

    tt[timeoutType] = setTimeout =>
      event.trigger this, 'timeout', [timeoutType]
      return if @job.done
      logger.error "Timeout ", timeoutType, " (", duration, " seconds) reached, abandoning job"
      tryCatch "Player#setErrorTimeout(page dump)", =>
        @page?.dumpPrivately()
      @job.fail 504, "timeout.#{timeoutType}"
    , duration * 1000

  clearErrorTimeout: (timeoutType) ->
    if @_timeouts?[timeoutType]
      logger.debug "Timeout ", timeoutType, " cleared"
      clearTimeout @_timeouts[timeoutType]

  onDocumentLoaded: (browser, page) ->
    return if @job.done or @job.paused

    module = @constructor.fid

    # log when alert and confirm are called
    new Bridge page, (bridge) =>
      bridge.evaluate ->
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

      , (data) =>
        # evaluated here
          unless data
            logger.debug "Bridge connected"
            return

          [messageType, message] = data
          formattedMessage = inspect message, undefined, undefined, color: prefs.get('wesabe.logger.color') ? on

          switch messageType
            when 'alert'
              logger.info messageType, ' called with message=', formattedMessage

            when 'confirm'
              logger.info messageType, ' called with message=', formattedMessage, ', automatically answered YES'

            when 'open'
              logger.info messageType, ' called with url=', formattedMessage

          callbacks = @["#{messageType}ReceivedCallbacks"]
          if callbacks
            for callback in callbacks
              @callWithMagicScope callback, browser, page, extend({message, logger: (require 'Logger').rootLogger}), message

    unless @shouldDispatch browser, page
      logger.info 'skipping document load'
      return

    @triggerDispatch browser, page

  triggerDispatch: (browser, page) ->
    module = @constructor.fid

    browser ||= @browser
    page ||= @page

    logger.info 'url=', page.url
    logger.info 'title=', page.title

    # these should not be used inside the FI scripts
    @browser = browser
    @page = page

    setTimeout =>
      for dispatch in @dispatches
        return if @job.done or @job.paused

        result = tryThrow "#{module}#dispatch(#{dispatch.name})", (log) =>
          @callWithAppropriateScope dispatch.callback, browser, page, {log}

        if result is false
          logger.info "dispatch chain halted"
          return
    , 2000

  onDownloadSuccessful: (browser, page) ->
    for callback in @afterDownloadCallbacks
      @runAction callback, browser, page

  shouldDispatch: (browser, page) ->
    for filter in @filters
      result = tryCatch "#{@constructor.fid}#filter(#{filter.name})", (log) =>
        switch r = @callWithAppropriateScope filter.test, browser, page, {log}
          when true
            log.debug "forcing dispatch"
          when false
            log.debug "aborting dispatch"

        return r

      # check for a definite answer
      return result if type.isBoolean result

    logger.debug "no filter voted to force or abort dispatch, so forcing dispatch by default"
    return true

  callWithAppropriateScope: (fn, browser, page, scope, args...) ->
    if func.argNames(fn).length > 0
      fn.call @, browser, page
    else
      @callWithMagicScope fn, browser, page, scope or {}

  callWithMagicScope: (fn, browser, page, scope, args...) ->
    log = scope.logger or scope.log or logger
    func.callWithScope fn, this, extend({
      browser
      page
      e: @constructor.elements
      answers: @answers
      options: @job.options
      tmp: @tmp
      action: @getActionProxy browser, page
      job: @getJobProxy()
      skipAccount: @skipAccount
      reload: => @triggerDispatch browser, page
      download: (args...) => @download args...
      bind: (args...) => Pathway.bind(args...)
      logger: log
      log: log
      isMagicScope: on
    }, scope or {}), args


  @::__defineGetter__ 'history', ->
    @_history ||= []

  @::__defineGetter__ 'tmp', ->
    @_tmp ||= {}

  @build: (fid) ->
    tryThrow "download.Player.build(fid=#{fid})", (log) =>
      klass = tryThrow "loading fi-scripts.#{fid}", =>
        wesabe.require "fi-scripts.#{fid}"

      new klass(fid)

class ActionProxy
  constructor: (@player, @browser, @page) ->

  __noSuchMethod__: (method, args) ->
    @player.runAction method, @browser, @page


module.exports = Player
