class Attribute
  constructor: (name, value) ->
    @name = name or ''
    @value = value or ''

  beginParsing: (parser) ->
    @trigger 'start-attribute', parser

  doneParsing: (parser) ->
    @parsed = true
    @trigger 'end-attribute attribute', parser

  trigger: (events, parser) ->
    parser.trigger events, [this]

  @::__defineGetter__ 'nodeName', ->
    @name

  @::__defineGetter__ 'nodeValue', ->
    @value

module.exports = Attribute
