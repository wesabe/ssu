wesabe.provide('download.Job')

class wesabe.download.Job
  constructor: (jobid, fid, creds, user_id, options) ->
    @jobid = jobid
    @fid = fid
    @creds = creds
    @user_id = user_id
    @status = 202
    @version = 0
    @data = {}
    @options = options || {}
    @options.goals = @options.goals || ['statements']
    @timer = new wesabe.util.Timer()

  update: (result, data) ->
    @version++
    @result = result
    @data[result] = data if data
    wesabe.info('Updating job to: ', result)
    wesabe.trigger(this, 'update')

  suspend: (result, data, callback) ->
    @version++
    player = @player
    @result = result;
    @data[result] = data

    if callback
      wesabe.bind(player, 'timeout', callback)
      wesabe.one this, 'resume', ->
        wesabe.unbind(player, 'timeout', callback)

    wesabe.warn('Suspending job for ', result, '=', data)
    wesabe.trigger(this, 'update suspend')

  resume: (creds) ->
    wesabe.warn('Resuming job')
    wesabe.trigger(this, 'resume')
    @update('resumed')
    @player.resume(creds)

  fail: (status, result) ->
    @finish(status, result, false)

  succeed: (status, result) ->
    @finish(status, result, true)

  finish: (status, result, successful) ->
    @version++
    event = if successful then 'succeed' else 'fail'
    @done = true
    if typeof @player.finish == 'function'
      @player.finish()
    @status = status || (if successful then 200 else 400)
    @result = result || (if successful then 'ok' else 'fail')
    wesabe.trigger(this, "update #{event} complete")
    @timer.end('Total')

    org = @player.org;
    summary = @timer.summarize()
    line = []
    total = parseFloat(summary['Total'])

    wesabe.info("Job completed #{if successful then '' else 'un'}sucessfully for #{org} (#{this.fid}) with status #{@status} (#{@result}) in #{Math.round(total/1000,2)}s")

    for label of summary
      continue if label == 'Total'

      line.push(label+': ')
      line.push(summary[label])
      line.push('ms')
      line.push(' (')
      line.push(parseInt((summary[label]/total)*100))
      line.push('%)')
      line.push(', ')

    line.push('Total: ')
    line.push(total)
    line.push('ms')

    wesabe.info.apply(wesabe, line)

  start: ->
    @player = wesabe.download.Player.build(@fid)
    @player.job = this

    wesabe.info("Starting job for #{@player.org} (#{@fid})")
    @player.start(@creds, document.getElementById('playback-browser'))

    wesabe.trigger(this, 'begin')
    @timer.start('Total')
    @nextGoal()

  nextGoal: ->
    if @options.goals.length
      @goal = @options.goals.shift()
      wesabe.info('Starting new goal: ', @goal)

      if @player.page
        @player.triggerDispatch()

      return @goal

    @player.onLastGoalFinished()
