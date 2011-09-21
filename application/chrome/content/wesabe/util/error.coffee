class StackTrace
  constructor: ->
    @frames = []

  addFrame: (args...) ->
    @frames.push new StackFrame(args...)

class StackFrame
  constructor: (@filename, @lineNumber, @name) ->
    if m = @filename.match /^chrome:\/\/[^\/]+\/content\/(.+)$/
      @filename = m[1]

  @::__defineGetter__ 'line', ->
    @_line ||= wesabe.getLineForStackFrame @

  @::__defineSetter__ 'line', (line) ->
    @_line = line

  contentForInspect: ->
    {@filename, @lineNumber, @name, @line}


stackTrace = (error) ->
  trace = new StackTrace

  if error.stack
    error.stack.replace /([^\r\n]+)\@([^\@\r\n]+?):(\d+)([\r\n]|$)/g, (everything, name, filename, lineNumber) ->
      trace.addFrame filename, lineNumber, name

  else if error.location
    frame = error.location
    while frame
      trace.addFrame frame.filename, frame.lineNumber, frame.name
      frame = frame.caller

  for frame in trace.frames
    wesabe.correctStackFrameInfo frame


  return trace


module.exports = {stackTrace}

#    frame.name ||= 'unknown'
#    frame.filename ||= 'unknown'
#    frame.lineNumber ||= '??'
#
#    m = frame.filename.match(/^(.*\/)coffee-script\.js$/)
#    if m
#      info = wesabe.getOriginalLineInfo(Number(frame.lineNumber))
#      if info?.file isnt 'wesabe.coffee'
#        frame.filename = m[1] + info.file
#        frame.lineNumber = "#{info.lineno} (eval line #{frame.lineNumber})"
#
#    contents = wesabe._getEvalText(frame.filename)?.split(/\n/)
#    if contents and frame.lineNumber isnt '??'
#      frame.lineNumber = Number(frame.lineNumber)
#      frame.lineText = contents[frame.lineNumber-1]
#      if frame.lineNumber < contents.length
#        for i in [frame.lineNumber..0]
#          if name = functionNameForLine(contents[i])
#            frame.name = name
#            break
#
#  if lineText = trace[0]?.lineText
#    lineText = trim(lineText)
#    lineText = lineText[0...38]+'...'+lineText[lineText.length-35...lineText.length] if lineText.length > 76
#
#    result += "On:\n    #{style 'error', lineText, color}\n"
#
#  result += "Backtrace:\n"
#
#  for {name, filename, lineNumber} in trace
#    if name.length < 40
#      result += ' ' for i in [0...(40 - name.length)]
#    else
#      name = "#{name[0...37]}..."
#
#    result += "#{name} at #{filename}:#{lineNumber}\n"
#
#  return result
#
#functionNameForLine = (line) ->
#  # foo: function(...)
#  if match = line.match(/([_a-zA-Z]\w*)\s*:\s*function\s*\(/)
#    match[1]
#
#  # function foo(...)
#  else if match = line.match(/function\s*([_a-zA-Z]\w*)\s*\([\)]*/)
#    match[1]
#
#  # get foo() / set foo(value)
#  else if match = line.match(/((?:get|set)\s+[_a-zA-Z]\w*)\(\)/)
#    match[1]
#
#  # Bar.prototype.foo = function(...)
#  else if match = line.match(/\.prototype\.([_a-zA-Z]\w*)\s*=\s*function/)
#    match[1]
#
#  # __defineGetter__('foo', function() / __defineSetter__('foo', function(...)
#  else if match = line.match(/__define([GS]et)ter__\(['"]([_a-zA-Z]\w*)['"],\s*function/)
#    "#{match[1].toLowerCase()} #{match[2]}"
