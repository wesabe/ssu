class StackTrace
  constructor: ->
    @frames = []

  addFrame: (args...) ->
    @frames.push new StackFrame(args...)

class StackFrame
  constructor: (@filename, @lineNumber, @name) ->
    if m = @filename.match /(?:^chrome:\/\/[^\/]+\/content)\/(.+)$/
      @filename = m[1]

  @::__defineGetter__ 'line', ->
    @_line ||= wesabe.getLineForStackFrame @

  @::__defineSetter__ 'line', (line) ->
    @_line = line

  contentForInspect: ->
    {@filename, @lineNumber, @name, @line}

MOZ_FRAME  = /([^\r\n]+)\@([^\@\r\n]+?):(\d+)(?:[\r\n]|$)/g
NODE_FRAME = /\s+at (.+) \((.+):(\d+):(\d+)\)\s*(?:[\r\n]|$)/g

stackTrace = (error) ->
  trace = new StackTrace

  if error.stack
    for pattern in [MOZ_FRAME, NODE_FRAME]
      error.stack.replace pattern, (everything, name, filename, lineNumber) ->
        trace.addFrame filename, lineNumber, name
      break if trace.frames.length > 0

  else if error.location
    frame = error.location
    while frame
      trace.addFrame frame.filename, frame.lineNumber, frame.name
      frame = frame.caller

  for frame in trace.frames
    wesabe.correctStackFrameInfo frame

  return trace


module.exports = {stackTrace}
