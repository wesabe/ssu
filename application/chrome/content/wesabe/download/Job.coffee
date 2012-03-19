date   = require 'lang/date'
extend = require 'lang/extend'
type   = require 'lang/type'
{uuid} = require 'lang/uuid'
Timer  = require 'util/Timer'

Page    = require 'dom/Page'
Browser = require 'dom/Browser'
Player  = require 'download/Player'
OFXPlayer = require 'download/OFXPlayer'
CompoundPlayer = require 'download/CompoundPlayer'

{EventEmitter} = require 'events2'

class Job extends EventEmitter
  constructor: (id, fid, creds, options) ->
    @id = id or uuid()
    @fid = fid
    @creds = creds
    @status = 202
    @version = 0
    @data = {}
    @options = options or {}
    @options.goals ||= ['statements']
    @options.since &&= date.parse(@options.since)
    @timer = new Timer()

  update: (result, data=null) ->
    @version++
    @result = result
    @data[result] = data if data
    logger.info 'Updating job to: ', result
    @emit 'update'

  suspend: (result, data, callback) ->
    @version++
    player = @player
    @result = result
    @data[result] = data

    if callback
      player.on 'timeout', callback
      @once 'resume', =>
        player.off 'timeout', callback

    logger.warn 'Suspending job for ', result, '=', data
    @emit 'update'
    @emit 'suspend'

  resume: (creds) ->
    logger.warn 'Resuming job'
    @emit 'resume'
    @update 'resumed'
    @player.resume creds

  fail: (status, result) ->
    @finish status, result, false

  succeed: (status, result) ->
    @finish status, result, true

  finish: (status, result, successful) ->
    @player?.finish?()
    @version++
    @status = status or (if successful then 200 else 400)
    @result = result or (if successful then 'ok' else 'fail')
    @emit 'update'
    @emit successful and 'succeed' or 'fail'
    @emit 'complete'
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
    @player.start @creds, new Browser()

    @emit 'begin'
    @timer.start 'Total'

  nextGoal: ->
    if @options.goals.length
      @goal = @options.goals.shift()
      logger.info 'Starting new goal: ', @goal

      if @player.page
        @player.triggerDispatch()

      return @goal

    @player.onLastGoalFinished()

  recordSuccessfulDownload: (file, metadata, reload=true) ->
    logger.info 'successfully downloaded file to ', file.path
    @data.downloads ||= []
    @data.downloads.push extend({path: file.path, status: 'ok'}, metadata or {})

  recordFailedDownload: (metadata, reload=true) ->
    logger.error 'failed to download file'
    @data.downloads ||= []
    @data.downloads.push(extend({status: 'error'}, metadata or {}))

  @::__defineGetter__ 'done', ->
    @status isnt 202


  contentForInspect: ->
    {@status, @result, @done, @options, @player, @data}

module.exports = Job
