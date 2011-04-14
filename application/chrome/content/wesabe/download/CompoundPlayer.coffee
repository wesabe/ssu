wesabe.provide('download.CompoundPlayer')

class wesabe.download.CompoundPlayer
  @register: (params) ->
    klass = @create(params)

    # make sure we put it where wesabe.require expects it
    wesabe.provide("fi-scripts.#{klass.fid}", klass)

    return klass

  @create: (params) ->
    class klass extends this
      @fid: params.fid
      @org: params.org

    wesabe.lang.extend(klass.prototype, params)

    return klass

  playerIndex: -1
  currentJob: null
  players: null

  start: (answers, browser) ->
    startNextPlayer = =>
      @playerIndex++
      @currentPlayer = new @players[@playerIndex]()
      wesabe.info("Starting player ", @currentPlayer)
      @currentPlayer.job = jobProxy
      @currentPlayer.start(answers, browser)

    jobProxy =
      update: (status, result) =>
        # proxy job updates through
        @job.update(status, result)

      fail: (status, result) =>
        wesabe.info("Could not complete job with ", @currentPlayer, " (", status, " ", result, ")")

        if @playerIndex+1 < @players.length
          startNextPlayer()
        else
          # no more players to try, report the last failure
          @job.fail(status, result)

      succeed: ->
        @job.succeed.apply(@job, arguments)

      timer: @job.timer

      nextGoal: ->
        @job.nextGoal.apply(@job, arguments)

      suspend: ->
        @job.suspend.apply(@job, arguments)

      options: @job.options

    jobProxy.__defineGetter__ 'page', =>
      @currentPlayer.page

    jobProxy.__defineGetter__ 'goal', =>
      @job.goal

    startNextPlayer()

  resume: ->
    @currentPlayer && @currentPlayer.resume()
