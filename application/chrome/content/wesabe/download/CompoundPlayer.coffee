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
  players: null

  start: (answers, browser) ->
    startNextPlayer = (failureCallback) =>
      nextPlayer()
      while @currentPlayer and not @currentPlayer.canHandleGoal(@job.goal)
        wesabe.warn("Skipping player ", @currentPlayer, " since it can't handle goal: ", @job.goal)
        nextPlayer()

      if @currentPlayer
        wesabe.info("Starting player ", @currentPlayer)
        @currentPlayer.job = @job
        @currentPlayer.start(answers, browser)
      else if failureCallback
        failureCallback()
      else
        wesabe.info("No more players to handle goal: ", @job.goal)
        @job.fail(400, "goal.unreachable")

    nextPlayer = =>
      @currentPlayer?.job = null

      if playerClass = @players[++@playerIndex]
        @currentPlayer = new playerClass()
        @currentPlayer.job = @job
      else
        @currentPlayer = null

    # customize fail to go to the next player
    job_fail_original = @job.fail
    @job.fail = (status, result) =>
      wesabe.info "Could not complete job with ", @currentPlayer, " (", status, " ", result, ")"

      # if we can't, just report the last failure
      startNextPlayer(=> job_fail_original(status, result))

    @job.__defineGetter__ 'page', =>
      @currentPlayer.page

    startNextPlayer()

  resume: (args...) ->
    @currentPlayer?.resume(args...)

  onLastGoalFinished: (args...) ->
    @currentPlayer?.onLastGoalFinished?(args...)

  onDownloadSuccessful: (args...) ->
    @currentPlayer?.onDownloadSuccessful?(args...)

  @::__defineGetter__ 'browser', ->
    @currentPlayer?.browser
