wesabe.provide('xml.Attribute')

class wesabe.xml.Attribute
  constructor: (name, value) ->
    @name = name || ''
    @value = value || ''

  beginParsing: (parser) ->
    @trigger('start-attribute', parser)

  doneParsing: (parser) ->
    @parsed = true
    @trigger('end-attribute attribute', parser)

  trigger: (events, parser) ->
    parser.trigger(events, [this])

  this::__defineGetter__ 'nodeName', ->
    @name

  this::__defineGetter__ 'nodeValue', ->
    @value
