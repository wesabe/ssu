wesabe.provide 'download.Job'

class wesabe.download.Job
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
    @options.since &&= wesabe.lang.date.parse(@options.since)
    @timer = new wesabe.util.Timer()

  update: (result, data) ->
    @version++
    @result = result
    @data[result] = data if data
    wesabe.info 'Updating job to: ', result
    wesabe.trigger this, 'update'

  suspend: (result, data, callback) ->
    @version++
    player = @player
    @result = result
    @data[result] = data

    if callback
      wesabe.bind player, 'timeout', callback
      wesabe.one this, 'resume', ->
        wesabe.unbind player, 'timeout', callback

    wesabe.warn('Suspending job for ', result, '=', data)
    wesabe.trigger this, 'update suspend'

  resume: (creds) ->
    wesabe.warn 'Resuming job'
    wesabe.trigger this, 'resume'
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
    @player.finish() if wesabe.isFunction @player.finish
    @status = status or (if successful then 200 else 400)
    @result = result or (if successful then 'ok' else 'fail')
    wesabe.trigger this, "update #{event} complete"
    @timer.end 'Total'

    org = @player.org
    summary = @timer.summarize()
    line = []
    total = Number(summary['Total'])

    wesabe.info "Job completed #{if successful then '' else 'un'}sucessfully for #{org} (#{@fid}) with status #{@status} (#{@result}) in #{Math.round(total/1000,2)}s"

  start: ->
    @player = wesabe.download.Player.build(@fid)
    @player.job = this
    @nextGoal()

    wesabe.info "Starting job for #{@player.org} (#{@fid})"
    @player.start @creds, document.getElementById('playback-browser')

    wesabe.trigger this, 'begin'
    @timer.start 'Total'

  nextGoal: ->
    if @options.goals.length
      @goal = @options.goals.shift()
      wesabe.info 'Starting new goal: ', @goal

      if @player.page
        @player.triggerDispatch()

      return @goal

    @player.onLastGoalFinished()

  recordSuccessfulDownload: (file, suggestedFilename, metadata, reload=true) ->
    wesabe.info 'successfully downloaded file to ', file.path
    @data.downloads ||= []
    @data.downloads.push wesabe.lang.extend({path: file.path, suggestedFilename: suggestedFilename, status: 'ok'}, metadata or {})
    @player.onDownloadSuccessful @player.browser, wesabe.dom.page.wrap(@player.browser.contentDocument) if reload

  recordFailedDownload: (metadata, reload=true) ->
    wesabe.error 'failed to download file'
    @data.downloads ||= []
    @data.downloads.push(wesabe.lang.extend({status: 'error'}, metadata or {}))
    @player.onDownloadSuccessful @player.browser, wesabe.dom.page.wrap(@player.browser.contentDocument) if reload
