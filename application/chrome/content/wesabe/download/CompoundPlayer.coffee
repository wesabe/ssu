extend = require 'lang/extend'
Player = require 'download/Player'

class CompoundPlayer extends Player
  @create: (params, callback) ->
    class klass extends this
      @fid: params.fid
      @org: params.org

    callback? klass

    extend klass.prototype, params

    return klass

  playerIndex: -1
  players: null

  start: (answers, browser) ->
    startNextPlayer = (failureCallback) =>
      nextPlayer()
      while @currentPlayer and not @currentPlayer.canHandleGoal(@job.goal)
        logger.warn "Skipping player ", @currentPlayer, " since it can't handle goal: ", @job.goal
        nextPlayer()

      if @currentPlayer
        logger.info "Starting player ", @currentPlayer
        @currentPlayer.job = @job
        @currentPlayer.start answers, browser
      else if failureCallback
        failureCallback()
      else
        logger.info "No more players to handle goal: ", @job.goal
        @job.fail 400, "goal.unreachable"

    nextPlayer = =>
      if playerClass = @players[++@playerIndex]
        @currentPlayer = new playerClass()
        @currentPlayer.job = @job
      else
        @currentPlayer = null

    # customize fail to go to the next player
    job_fail_original = @job.fail
    @job.fail = (status, result) =>
      logger.info "Could not complete job with ", @currentPlayer, " (", status, " ", result, ")"

      # if we can't, just report the last failure
      startNextPlayer(=> job_fail_original.call(@job, status, result))

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


module.exports = CompoundPlayer
