type       = require 'lang/type'
array      = require 'lang/array'
{trim}     = require 'lang/string'
Colorizer  = require 'util/Colorizer'

# lazy-load the sanitize method
sanitize = (args...) ->
  {sanitize} = require 'util/privacy'
  sanitize args...

COLOR_SCHEME =
  number:    ['blue']
  string:    ['green']
  shell:     ['cyan']
  class:     ['cyan']
  undefined: ['black']
  boolean:   ['yellow']
  regexp:    ['red']
  error:     ['red']
  punct:     ['yellow']

#
# Inspect takes any JavaScript value and returns a string representing
# that value, optionally showing hidden properties of that value if
# applicable, recursing to a specific depth if applicable, and optionally
# returning a string using ANSI color escapes suitable for printing to
# a terminal.
#

inspect = (object, showHidden=off, depth=2, color=off) ->
  classForInspect = object?.classForInspect?()

  if typeof object is 'undefined'
    style 'undefined', 'undefined', color
  else if object is null
    style 'null', 'null', color
  else if classForInspect is Boolean or object is true or object is false
    style 'boolean', object.toString(), color
  else if classForInspect is Array or type.isArray(object) or type.is(object, HTMLCollection)
    inspectArray object, showHidden, depth, color
  else if classForInspect is RegExp or type.isRegExp object
    inspectRegExp object, color
  else if classForInspect in [Element, HTMLElement, XULElement] or type.is object, Element
    inspectElement object, color
  else if classForInspect is Number or typeof object is 'number'
    inspectNumber object, color
  else if classForInspect is String or typeof object is 'string'
    inspectString object, color
  else if classForInspect is Function or type.isFunction object
    inspectFunction object, color
  else if type.isFunction object.inspect
    object.inspect showHidden, depth, color
  # else if object instanceof Error
  #   inspectError object, color
  else if classForInspect is Object or typeof object is 'object'
    inspectObject object, showHidden, depth, color
  else
    "#{object}"


#
# Helper functions for +inspect+.
#

style = (type, text, color) ->
  if color and colors = COLOR_SCHEME[type]
    "#{(Colorizer[c]() for c in colors).join('')}#{text}#{Colorizer.reset()}"
  else
    text

inspectObject = (object, showHidden, depth, color) ->
  return style 'shell', object.toString(), color if depth < 0

  # allow the object to override the thing we display as its content
  content = object.contentForInspect?()

  # if it's a simple object then just enumerate the properties
  if not content or content?.constructor is Object
    content ||= object

    properties = for own k of content
      getter = content.__lookupGetter__? k
      setter = content.__lookupSetter__? k
      if getter or setter
        string = "["
        string += "Getter" if getter
        string += "/" if getter and setter
        string += "Setter" if setter
        string += "]"
        "#{k}: #{style 'shell', string, color}"
      else
        "#{k}: #{inspect content[k], showHidden, depth-1, color}"

    contentString = properties.join ', '
  else
    # otherwise do a full inspect call on it
    contentString = inspect content, showHidden, depth-1, color

  string = "{"
  if object.constructor isnt Object and object.constructor?.name
    string += style 'class', object.constructor.name, color
    string += " " if contentString.length
  string += contentString
  string += "}"

inspectArray = (object, showHidden, depth, color) ->
  if object.length is 0
    '[]'
  else if depth < 0
    style 'shell', Object.prototype.toString.call(object), color
  else
    "[ #{(for own k, v of object
      # non-numeric index, show it
      prefix = if Number(k).toString() is k then "" else "#{k}: "

      "#{prefix}#{inspect v, showHidden, depth-1, color}").join(', ')} ]"

inspectNumber = (number, color) ->
  style 'number', number, color

inspectString = (string, color) ->
  string = string.replace /'/g, "\\'"
  string = "'#{string}'"
  style 'string', string, color

inspectFunction = (fn, color) ->
  string = "[Function"
  string += ": #{fn.name}" if fn.name
  string += "]"
  style 'shell', string, color

inspectRegExp = (regexp, color) ->
  style 'regexp', regexp.toSource(), color

inspectElement = (element, color) ->
  attrs = (" #{nodeName}#{style 'punct', '=', color}#{inspect nodeValue, undefined, undefined, color}" for {nodeName, nodeValue} in element.attributes).join('')
  "#{style 'punct', '<', color}#{element.tagName}#{attrs}#{style 'punct', '>', color}"

inspectError = (error, color) ->
  result = "An exception has occurred:\n    #{style 'error', error.message, color}" +
    " (#{error.name})\n"

  trace = []
  files = {}

  if error.stack
    error.stack.replace /([^\r\n]+)\@([^\@\r\n]+?):(\d+)([\r\n]|$)/g, (everything, call, file, lineno) ->
      trace.push
        name: call
        filename: file
        lineNumber: lineno
  else if error.location
    frame = error.location
    while frame
      trace.push
        name: frame.name
        filename: frame.filename
        lineNumber: frame.lineNumber
      frame = frame.caller

  for frame in trace
    frame.name ||= 'unknown'
    frame.filename ||= 'unknown'
    frame.lineNumber ||= '??'

    m = frame.filename.match(/^(.*\/)wesabe\.js$/)
    if m
      info = wesabe.fileAndLineFromEvalLine(Number(frame.lineNumber))
      if info?.file isnt 'wesabe.coffee'
        frame.filename = m[1] + info.file
        frame.lineNumber = "#{info.lineno} (eval line #{frame.lineNumber})"

    m = frame.filename.match(/^chrome:\/\/[^\/]+\/content\/(.*)$/)
    if m
      frame.filename = m[1]

    contents = wesabe._getEvalText(frame.filename)?.split(/\n/)
    if contents and frame.lineNumber isnt '??'
      frame.lineNumber = Number(frame.lineNumber)
      frame.lineText = contents[frame.lineNumber-1]
      if frame.lineNumber < contents.length
        for i in [frame.lineNumber..0]
          if name = functionNameForLine(contents[i])
            frame.name = name
            break

  if lineText = trace[0]?.lineText
    lineText = trim(lineText)
    lineText = lineText[0...38]+'...'+lineText[lineText.length-35...lineText.length] if lineText.length > 76

    result += "On:\n    #{style 'error', lineText, color}\n"

  result += "Backtrace:\n"

  for {name, filename, lineNumber} in trace
    if name.length < 40
      result += ' ' for i in [0...(40 - name.length)]
    else
      name = "#{name[0...37]}..."

    result += "#{name} at #{filename}:#{lineNumber}\n"

  return result

functionNameForLine = (line) ->
  # foo: function(...)
  if match = line.match(/([_a-zA-Z]\w*)\s*:\s*function\s*\(/)
    match[1]

  # function foo(...)
  else if match = line.match(/function\s*([_a-zA-Z]\w*)\s*\([\)]*/)
    match[1]

  # get foo() / set foo(value)
  else if match = line.match(/((?:get|set)\s+[_a-zA-Z]\w*)\(\)/)
    match[1]

  # Bar.prototype.foo = function(...)
  else if match = line.match(/\.prototype\.([_a-zA-Z]\w*)\s*=\s*function/)
    match[1]

  # __defineGetter__('foo', function() / __defineSetter__('foo', function(...)
  else if match = line.match(/__define([GS]et)ter__\(['"]([_a-zA-Z]\w*)['"],\s*function/)
    "#{match[1].toLowerCase()} #{match[2]}"


module.exports = inspect

##
## Converts +object+ into a string representation suitable for debugging.
## @method inspect
## @param object {Object} The object to inspect.
##
#inspect = (object, refs=[], color=false, tainted=false) ->
#  _inspect(object, refs, color, tainted)
#
#inspectForLog = (object, refs=[], color=wesabe.logger?.colorizeLogging, tainted=false) ->
#  _inspect(object, refs, color, tainted)
#
##
## Generates an inspect function suitable for use in a class prototype.
## @method inspectorFor
## @param klass {String} The name of the class the function will be used with.
##
#inspectorFor = (klass) ->
#  return ->
#    "#<#{klass}#{_inspectAttributes(this, [this])}>"
#
##
## Internal logic for inspect.
## @method _inspect
## @param object {Object} The object to inspect.
## @param refs {Array} The objects already inspected in this call to inspect.
## @private
##
#_inspect = (object, refs, color, tainted) ->
#  for ref in refs
#    return '...' if object == ref
#
#  refs.push(object) if typeof object is 'object'
#
#  return object.inspect(refs, color, tainted) if object?.inspect?
#
#  t = typeof object
#
#  if type.isTainted(object)
#    _inspectTainted(object, refs, color)
#  else if t is 'function'
#    s = new Colorizer()
#    s.print('[Function')
#    s.print(": #{object.name}") if object.name
#    s.print(']').toString()
#  else if t is 'number'
#    object.toString()
#  else if object == null
#    'null'
#  else if t == 'undefined'
#    'undefined'
#  else if object == true
#    'true'
#  else if object == false
#    'false'
#  else if t == 'string'
#    _inspectString(object, color, tainted)
#  else if object instanceof Array
#    "[#{(_inspect(o, refs, color, tainted) for o in object).join(', ')}]"
#  else if object instanceof HTMLElement
#    _inspectElement(object, color, tainted)
#  else if object instanceof XULElement
#    _inspectElement(object, color, tainted)
#  else if object instanceof Window
#    _inspectWindow(object, color, tainted)
#  else if object instanceof RegExp
#    _inspectRegExp(object, color, tainted)
#  else if type.isDate(object)
#    _inspectString(object.toString(), color, tainted)
#  else if object.nodeType == Node.TEXT_NODE
#    "{text #{inspect(object.nodeValue, tainted)}}"
#  else if (object.constructor == Error) ||
#           (object.constructor == TypeError) ||
#           (object.constructor == ReferenceError) ||
#           (object.constructor == InternalError) ||
#           (object.constructor == SyntaxError) ||
#           (object.message && object.location && object.filename)
#    _inspectError(object, refs, color, tainted)
#  else
#    _inspectObject(object, refs, color, tainted)
#
#_inspectError = (error, refs, color, tainted) ->
#  s = new Colorizer()
#  s.disabled = !color
#  s.reset()
#   .print('An exception has occurred:\n    ')
#   .red(error.message)
#   .print(' (', error.name, ')\n')
#
#  trace = []
#  files = {}
#
#  if error.stack
#    error.stack.replace /([^\r\n]+)\@([^\@\r\n]+?):(\d+)([\r\n]|$)/g, (everything, call, file, lineno) ->
#      trace.push
#        name: call
#        filename: file
#        lineNumber: lineno
#  else if error.location
#    frame = error.location
#    while frame
#      trace.push
#        name: frame.name
#        filename: frame.filename
#        lineNumber: frame.lineNumber
#      frame = frame.caller
#
#  for frame in trace
#    frame.name ||= 'unknown'
#    frame.filename ||= 'unknown'
#    frame.lineNumber ||= '??'
#
#    m = frame.filename.match(/^(.*\/)wesabe\.js$/)
#    if m
#      info = wesabe.fileAndLineFromEvalLine(parseInt(frame.lineNumber, 10))
#      if info?.file != 'wesabe.js'
#        frame.filename = m[1] + info.file
#        frame.lineNumber = "#{info.lineno} (eval line #{frame.lineNumber})"
#
#    m = frame.filename.match(/^chrome:\/\/[^\/]+\/content\/(.*)$/)
#    if m
#      frame.filename = m[1]
#
#    contents = wesabe._getEvalText(frame.filename)?.split(/\n/)
#    if contents && frame.lineNumber != '??'
#      frame.lineNumber = parseInt(frame.lineNumber, 10)
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
#    s.print('On:\n    ')
#     .red(lineText)
#     .print('\n')
#
#  s.print('Backtrace:\n')
#
#  for {name, filename, lineNumber} in trace
#    if name.length < 40
#      s.print(' ') for i in [0...(40 - name.length)]
#    else
#      name = "#{name[0...37]}..."
#
#    s.print(name, ' at ', filename, ':', lineNumber, '\n')
#
#  return s.toString()
#
#_inspectTainted = (object, refs, color) ->
#  if wesabe.logger.level == wesabe.logger.levels.radioactive
#    # don't sanitize on radioactive
#    return _inspect(object.untaint(), refs, color, false)
#
#  s = new Colorizer()
#  s.disabled = !color
#
#  s.bold('{sanitized ')
#   .print(_inspect(object.untaint(), refs, color, true))
#   .bold('}')
#   .toString()
#
#_inspectObject = (object, refs, color, tainted) ->
#  s = new Colorizer()
#  s.disabled = !color
#  modName = (o, prefix) ->
#    name = o?.__module__?.fullName
#    if name && prefix
#      prefix+name
#    else
#      name
#
#  s.yellow('#<')
#   .bold(modName(object, 'module:') || modName(object.constructor) || 'Object')
#   .print(_inspectAttributes(object, refs, color, tainted))
#   .yellow('>')
#   .toString()
#
##
## Generates a string which could be re-eval'ed to get the original string.
## @method _inspectString
## @param string {String} The string to inspect.
## @private
##
#_inspectString = (string, color, tainted) ->
#  s = new Colorizer()
#  s.disabled = !color
#  map = {"\n": "\\n", "\t": "\\t", '"': '\\"', "\r": "\\r"}
#  value = string.replace(/(["\n\r\t])/g, (s) -> map[s])  # fix syntax highlighter in vim "
#
#  if tainted
#    value = sanitize(value)
#
#  s.yellow('"').green(value).yellow('"').toString()
#
#_inspectRegExp = (regexp, color, tainted) ->
#  s = new Colorizer()
#  s.disabled = !color
#
#  s.yellow(regexp.toSource()).toString()
#
##
## Generates a string inspecting the attributes of +object+.
## @method _inspectAttributes
## @param object {Object} The object whose attributes will be inspected.
## @param refs {Array} The objects already inspected in this call to inspect.
## @private
##
#_inspectAttributes = (object, refs, color, tainted) ->
#  s = new Colorizer()
#  s.disabled = !color
#  pairs = []
#  keys = []
#
#  for key of object
#    keys.push(key)
#
#  for key in keys.sort()
#    continue if type.isFunction(object[key]) || key.match(/^__/)
#    s.print(_inspectAttribute(key, object[key], refs, color, tainted))
#
#  return s.toString()
#
#_inspectAttribute = (key, value, refs, color, tainted) ->
#    new Colorizer().print(' ')
#                               .underlined(key)
#                               .yellow('=')
#                               .print(_inspect(value, refs, color, tainted))
#                               .toString()
#
##
## Generate a string inspecting the given +element+.
## @method _inspectElement
## @param element {HTMLElement} The element to inspect.
## @private
##
#_inspectElement = (element, color, tainted) ->
#  s = new Colorizer()
#  s.disabled = !color
#  s.yellow('<')
#   .white()
#   .bold()
#   .print(element.tagName.toLowerCase())
#   .reset()
#
#  for attr in array.from(element.attributes)
#    value = attr.nodeValue.toString()
#    value = sanitize(value) if tainted
#
#    s.print(' ')
#     .underlined(attr.nodeName)
#     .yellow('="')
#     .green(value)
#     .yellow('"')
#
#  s.yellow('>').toString()
#
##
## Generate a string inspecting the given +window+.
##
#_inspectWindow = (window, color, tainted) ->
#  s = new Colorizer()
#  s.disabled = !color
#
#  s.yellow('#<')
#   .white()
#   .bold()
#   .print("Window ")
#   .reset()
#   .underlined('title')
#   .yellow('=')
#   .print(_inspectString(window.document.title,color,tainted))
#   .yellow('>')
#   .toString()
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
#
#wesabe.util.inspect = inspect
#wesabe.util.inspectForLog = inspectForLog
#wesabe.util.inspectorFor = inspectorFor
#
## FIXME: restructure the inspect API to remove the need to expose these
#wesabe.util._inspect = _inspect
#wesabe.util._inspectString = _inspectString
