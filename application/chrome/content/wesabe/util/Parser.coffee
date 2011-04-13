wesabe.provide('util.Parser')

class wesabe.util.Parser
  this::__defineSetter__ 'tokens', (tokens) ->
    @__tokens__ = for own tok, callback of tokens
                    {pattern: new RegExp("^#{tok}$")
                    callback: callback}

  parse: (what) ->
    @parsing = what
    @offset = 0

    eof = true

    while !@hasStopRequest && @offset < what.length
      if !@process(what[@offset])
        eof = false
        break

    @process('EOF') if eof && !@hasStopRequest
    delete @parsing

  stop: ->
    @hasStopRequest = true

  process: (p) ->
    patterns = []

    for {pattern, callback} in @__tokens__
      patterns.push(pattern)
      if pattern.test(p)
        if wesabe.isFunction(callback)
          # call the provided callback function
          retval = callback(p)
        else
          throw new Error("Unknown callback type ", callback, ", please pass a Function or a Parser")

        @offset++
        return retval != false

    throw new Error("Unexpected #{p} (offset=#{@offset}, before=#{
                    wesabe.util.inspect(@parsing[@offset-15...@offset])
                    }, after=#{
                    wesabe.util.inspect(@parsing[@offset...@offset+15])
                    }, together=#{
                    wesabe.util.inspect(@parsing[@offset-15...@offset+15])
                    }) while looking for one of #{
                    wesabe.util.inspect(patterns)}")

  trigger: (events, args) ->
    wesabe.trigger(this, events, args)
