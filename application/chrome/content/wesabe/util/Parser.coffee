{isFunction}   = require 'lang/type'
inspect        = require 'util/inspect'
{EventEmitter} = require 'events2'

class Parser extends EventEmitter
  @::__defineSetter__ 'tokens', (tokens) ->
    @__tokens__ = for own tok, callback of tokens
                    {pattern: new RegExp("^#{tok}$"), callback}

  parse: (what) ->
    @parsing = what
    @offset = 0

    eof = true

    while not @hasStopRequest and @offset < what.length
      if not @process(what[@offset])
        eof = false
        break

    @process 'EOF' if eof unless @hasStopRequest
    delete @parsing

  stop: ->
    @hasStopRequest = true

  process: (p) ->
    patterns = []

    for {pattern, callback} in @__tokens__
      patterns.push(pattern)
      if pattern.test(p)
        if isFunction callback
          # call the provided callback function
          retval = callback(p)
        else
          throw new Error("Unknown callback type ", callback, ", please pass a Function or a Parser")

        @offset++
        return retval isnt false

    throw new Error("Unexpected #{p} (offset=#{@offset}, before=#{
                    inspect @parsing[@offset-15...@offset]
                    }, after=#{
                    inspect @parsing[@offset...@offset+15]
                    }, together=#{
                    inspect @parsing[@offset-15...@offset+15]
                    }) while looking for one of #{
                    inspect patterns}")

  trigger: (events, args) ->
    for event in events.split(' ')
      @emit event, args...

module.exports = Parser
