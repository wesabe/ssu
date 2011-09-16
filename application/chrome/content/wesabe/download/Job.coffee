date   = require 'lang/date'
extend = require 'lang/extend'
type   = require 'lang/type'
event  = require 'util/event'
Timer  = require 'util/Timer'

Page    = require 'dom/Page'
Browser = require 'dom/Browser'
Player  = require 'download/Player'

class Job
  constructor: (jobid, fid, creds, user_id, options) ->
    @jobid = jobid
    @fid = fid
    @creds = creds
    @user_id = user_id
    @status = 202
    @done = false
    @version = 0
    @data = {}
    @options = options or {}
    @options.goals ||= ['statements']
    @options.since &&= date.parse(@options.since)
    @timer = new Timer()

  update: (result, data) ->
    @version++
    @result = result
    @data[result] = data if data
    logger.info 'Updating job to: ', result
    event.trigger this, 'update'

  suspend: (result, data, callback) ->
    @version++
    player = @player
    @result = result
    @data[result] = data

    if callback
      event.add player, 'timeout', callback
      event.one this, 'resume', ->
        event.remove player, 'timeout', callback

    logger.warn 'Suspending job for ', result, '=', data
    event.trigger this, 'update suspend'

  resume: (creds) ->
    logger.warn 'Resuming job'
    event.trigger this, 'resume'
    @update 'resumed'
    @player.resume creds

  fail: (status, result) ->
    @finish status, result, false

  succeed: (status, result) ->
    @finish status, result, true

  finish: (status, result, successful) ->
    @version++
    event = if successful then 'succeed' else 'fail'
    @done = true
    @player.finish() if type.isFunction @player.finish
    @status = status or (if successful then 200 else 400)
    @result = result or (if successful then 'ok' else 'fail')
    event.trigger this, "update #{event} complete"
    @timer.end 'Total'

    org = @player.org
    summary = @timer.summarize()
    line = []
    total = Number summary.Total

    logger.info "Job completed #{if successful then '' else 'un'}sucessfully for #{org} (#{@fid}) with status #{@status} (#{@result}) in #{Math.round total/1000,2}s"

  start: ->
    @player = Player.build(@fid)
    @player.job = this
    @nextGoal()

    logger.info "Starting job for #{@player.org} (#{@fid})"
    @player.start @creds, document.getElementById('playback-browser')

    event.trigger this, 'begin'
    @timer.start 'Total'

  nextGoal: ->
    if @options.goals.length
      @goal = @options.goals.shift()
      logger.info 'Starting new goal: ', @goal

      if @player.page
        @player.triggerDispatch()

      return @goal

    @player.onLastGoalFinished()

  recordSuccessfulDownload: (file, suggestedFilename, metadata, reload=true) ->
    logger.info 'successfully downloaded file to ', file.path
    @data.downloads ||= []
    @data.downloads.push extend({path: file.path, suggestedFilename: suggestedFilename, status: 'ok'}, metadata or {})

    if reload
      browser = Browser.wrap(@player.browser)
      @player.onDownloadSuccessful browser, browser.mainPage

  recordFailedDownload: (metadata, reload=true) ->
    logger.error 'failed to download file'
    @data.downloads ||= []
    @data.downloads.push(extend({status: 'error'}, metadata or {}))

    if reload
      browser = Browser.wrap(@player.browser)
      @player.onDownloadSuccessful browser, browser.mainPage

module.exports = Job
