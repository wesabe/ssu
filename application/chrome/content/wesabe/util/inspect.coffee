type       = require 'lang/type'
array      = require 'lang/array'
{trim}     = require 'lang/string'
Colorizer  = require 'util/Colorizer'

# lazy-load the sanitize/untaint methods
sanitize = (args...) ->
  {sanitize} = require 'util/privacy'
  sanitize args...
untaint = (args...) ->
  {untaint} = require 'util/privacy'
  untaint args...

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

inspect = (object, showHidden=off, depth=2, opts={}) ->
  opts.color    ?= off
  opts.sanitize ?= type.isTainted object

  object = untaint object if type.isTainted object
  classForInspect = object?.classForInspect?()

  if opts.sanitize
    prefix = "{sanitized "
    suffix = "}"
  else
    prefix = ""
    suffix = ""

  "#{prefix}#{
  if typeof object is 'undefined'
    style 'undefined', 'undefined', opts
  else if object is null
    style 'null', 'null', opts
  else if classForInspect is Boolean or object is true or object is false
    style 'boolean', object.toString(), opts
  else if classForInspect is Array or type.isArray(object) or (HTMLCollection? and type.is(object, HTMLCollection))
    inspectArray object, showHidden, depth, opts
  else if classForInspect is RegExp or type.isRegExp object
    inspectRegExp object, opts
  else if classForInspect in [Element?, HTMLElement?, XULElement?] or (Element? and type.is object, Element)
    inspectElement object, opts
  else if classForInspect is Number or typeof object is 'number'
    inspectNumber object, opts
  else if classForInspect is String or typeof object is 'string'
    inspectString object, opts
  else if classForInspect is Function or type.isFunction object
    inspectFunction object, opts
  else if type.isFunction object.inspect
    object.inspect showHidden, depth, opts
  # else if object instanceof Error
  #   inspectError object, opts
  else if classForInspect is Object or typeof object is 'object'
    inspectObject object, showHidden, depth, opts
  else
    "#{object}"
  }#{suffix}"


#
# Helper functions for +inspect+.
#

style = (type, text, opts) ->
  text = sanitize text if opts.sanitize

  if opts.color and colors = COLOR_SCHEME[type]
    "#{(Colorizer[c]() for c in colors).join('')}#{text}#{Colorizer.reset()}"
  else
    text

inspectObject = (object, showHidden, depth, opts) ->
  return style 'shell', object.toString(), opts if depth < 0

  # allow the object to override the thing we display as its content
  content = object.contentForInspect?()

  # if it's a simple object then just enumerate the properties
  if not content or content.constructor?.name in ['Object', null, undefined]
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
        "#{k}: #{style 'shell', string, opts}"
      else
        "#{k}: #{inspect content[k], showHidden, depth-1, opts}"

    contentString = properties.join ', '
  else
    # otherwise do a full inspect call on it
    contentString = inspect content, showHidden, depth-1, opts

  string = "{"
    string += style 'class', object.constructor.name, opts
    string += " " if contentString.length
  string += contentString
  if object.constructor?.name not in ['Object', null, undefined]
  string += "}"

inspectArray = (object, showHidden, depth, opts) ->
  if object.length is 0
    '[]'
  else if depth < 0
    style 'shell', Object.prototype.toString.call(object), opts
  else
    "[ #{(for own k, v of object
      # non-numeric index, show it
      prefix = if Number(k).toString() is k then "" else "#{k}: "

      "#{prefix}#{inspect v, showHidden, depth-1, opts}").join(', ')} ]"

inspectNumber = (number, opts) ->
  style 'number', number, opts

inspectString = (string, opts) ->
  string = string.replace /'/g, "\\'"
  string = "'#{string}'"
  style 'string', string, opts

inspectFunction = (fn, opts) ->
  string = "[Function"
  string += ": #{fn.name}" if fn.name
  string += "]"
  style 'shell', string, opts

inspectRegExp = (regexp, opts) ->
  style 'regexp', regexp.toString(), opts

inspectElement = (element, opts) ->
  attrs = (" #{nodeName}#{style 'punct', '=', opts}#{inspect nodeValue, undefined, undefined, opts}" for {nodeName, nodeValue} in element.attributes).join('')
  "#{style 'punct', '<', opts}#{element.tagName}#{attrs}#{style 'punct', '>', opts}"

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
