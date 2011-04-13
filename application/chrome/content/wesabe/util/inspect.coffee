wesabe.provide('util.inspect')

#
# Converts +object+ into a string representation suitable for debugging.
# @method inspect
# @param object {Object} The object to inspect.
#
inspect = (object) ->
  _inspect(object, [], false)

inspectForLog = (object) ->
  _inspect(object, [], wesabe.logger?.colorizeLogging)

#
# Generates an inspect function suitable for use in a class prototype.
# @method inspectorFor
# @param klass {String} The name of the class the function will be used with.
#
inspectorFor = (klass) ->
  return ->
    "#<#{klass}#{_inspectAttributes(this, [this])}>"

#
# Internal logic for inspect.
# @method _inspect
# @param object {Object} The object to inspect.
# @param refs {Array} The objects already inspected in this call to inspect.
# @private
#
_inspect = (object, refs, color, tainted) ->
  for ref in refs
    return '...' if object == ref

  refs.push(object)

  return object.inspect(refs, color, tainted) if object?.inspect?

  t = typeof object

  if wesabe.isTainted(object)
    _inspectTainted(object, refs, color)
  else if t == 'function'
    '#<Function>'
  else if t == 'number'
    object.toString()
  else if object == null
    'null'
  else if t == 'undefined'
    'undefined'
  else if object == true
    'true'
  else if object == false
    'false'
  else if t == 'string'
    _inspectString(object, color, tainted)
  else if object instanceof Array
    "[#{(_inspect(o, refs, color, tainted) for o in object).join(', ')}]"
  else if object instanceof HTMLElement
    _inspectElement(object, color, tainted)
  else if object instanceof XULElement
    _inspectElement(object, color, tainted)
  else if object instanceof Window
    _inspectWindow(object, color, tainted)
  else if object instanceof RegExp
    _inspectRegExp(object, color, tainted)
  else if wesabe.isDate(object)
    _inspectString(object.toString(), color, tainted)
  else if object.nodeType == Node.TEXT_NODE
    "{text #{inspect(object.nodeValue, tainted)}}"
  else if (object.constructor == Error) ||
           (object.constructor == TypeError) ||
           (object.constructor == ReferenceError) ||
           (object.constructor == InternalError) ||
           (object.constructor == SyntaxError) ||
           (object.message && object.location && object.filename)
    _inspectError(object, refs, color, tainted)
  else
    _inspectObject(object, refs, color, tainted)

_inspectError = (error, refs, color, tainted) ->
  s = new wesabe.util.Colorizer()
  s.disabled = !color
  s.reset()
   .print('An exception has occurred:\n    ')
   .red(error.message)
   .print(' (', error.name, ')\n')
   .print('Backtrace:\n')

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
      trace.push(frame)
      frame = frame.caller

  for frame in trace
    name = frame.name||'unknown'
    file = frame.filename||'unknown'
    lineno = frame.lineNumber||'??'

    m = file.match(/^(.*\/)wesabe\.js$/)
    if m
      info = wesabe.fileAndLineFromEvalLine(parseInt(lineno, 10))
      if info && info.file != 'wesabe.js'
        file = m[1] + info.file
        lineno = "#{info.lineno} (eval line #{lineno})"

    m = file.match(/^chrome:\/\/[^\/]+\/content\/(.*)$/)
    if m
      file = m[1]

    contents = (files[file] ||= (wesabe._getText(file) || '').split(/\n/))
    if contents && lineno != '??'
      lineno = parseInt(lineno, 10)
      if lineno < contents.length
        for i in [lineno..0]
          m = contents[i].match(/([a-zA-Z]\w*)\s*:\s*function\s*\(|function\s*([a-zA-Z]\w*)\s*\([\)]*|((?:get|set)\s+[a-zA-Z]\w*)\(\)/)
        if m
          name = m[1] || m[2] || m[3]
          break

    if name.length < 40
      s.print(' ') for i in [0...(40 - name.length)]
    else
      name = "#{name[0...37]}..."

    s.print(name, ' at ', file, ':', lineno, '\n')

  return s.toString()

_inspectTainted = (object, refs, color) ->
  if wesabe.logger.level == wesabe.logger.levels.radioactive
    # don't sanitize on radioactive
    return _inspect(object.untaint(), refs, color, false)

  s = new wesabe.util.Colorizer()
  s.disabled = !color

  s.bold('{sanitized ')
   .print(_inspect(object.untaint(), refs, color, true))
   .bold('}')
   .toString()

_inspectObject = (object, refs, color, tainted) ->
  s = new wesabe.util.Colorizer()
  s.disabled = !color
  modName = (o, prefix) ->
    name = o?.__module__?.fullName
    if name && prefix
      prefix+name
    else
      name

  s.yellow('#<')
   .bold(modName(object, 'module:') || modName(object.constructor) || 'Object')
   .print(_inspectAttributes(object, refs, color, tainted))
   .yellow('>')
   .toString()

#
# Generates a string which could be re-eval'ed to get the original string.
# @method _inspectString
# @param string {String} The string to inspect.
# @private
#
_inspectString = (string, color, tainted) ->
  s = new wesabe.util.Colorizer()
  s.disabled = !color
  map = {"\n": "\\n", "\t": "\\t", '"': '\\"', "\r": "\\r"}
  value = string.replace(/(["\n\r\t])/g, (s) -> map[s])  # fix syntax highlighter in vim "

  if tainted
    value = wesabe.util.privacy.sanitize(value)

  s.yellow('"').green(value).yellow('"').toString()

_inspectRegExp = (regexp, color, tainted) ->
  s = new wesabe.util.Colorizer()
  s.disabled = !color

  s.yellow(regexp.toSource()).toString()

#
# Generates a string inspecting the attributes of +object+.
# @method _inspectAttributes
# @param object {Object} The object whose attributes will be inspected.
# @param refs {Array} The objects already inspected in this call to inspect.
# @private
#
_inspectAttributes = (object, refs, color, tainted) ->
  s = new wesabe.util.Colorizer()
  s.disabled = !color
  pairs = []
  keys = []

  for key of object
    keys.push(key)

  for key in keys.sort()
    continue if wesabe.isFunction(object[key]) || key.match(/^__/)

    s.print(' ')
     .underlined(key)
     .yellow('=')
     .print(_inspect(object[key], refs, color, tainted))

  s.toString()

#
# Generate a string inspecting the given +element+.
# @method _inspectElement
# @param element {HTMLElement} The element to inspect.
# @private
#
_inspectElement = (element, color, tainted) ->
  s = new wesabe.util.Colorizer()
  s.disabled = !color
  s.yellow('<')
   .white()
   .bold()
   .print(element.tagName.toLowerCase())
   .reset()

  for attr in wesabe.lang.array.from(element.attributes)
    value = attr.nodeValue.toString()
    value = wesabe.util.privacy.sanitize(value) if tainted

    s.print(' ')
     .underlined(attr.nodeName)
     .yellow('="')
     .green(value)
     .yellow('"')

  s.yellow('>').toString()

#
# Generate a string inspecting the given +window+.
#
_inspectWindow = (window, color, tainted) ->
  s = new wesabe.util.Colorizer()
  s.disabled = !color

  s.yellow('#<')
   .white()
   .bold()
   .print("Window ")
   .reset()
   .underlined('title')
   .yellow('=')
   .print(_inspectString(window.document.title,color,tainted))
   .yellow('>')
   .toString()

wesabe.util.inspect = inspect
wesabe.util.inspectForLog = inspectForLog
wesabe.util.inspectorFor = inspectorFor

# FIXME: restructure the inspect API to remove the need to expose these
wesabe.util._inspect = _inspect
wesabe.util._inspectString = _inspectString
