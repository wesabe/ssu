Element = require 'xml/Element'

class CloseTag
  constructor: (name) ->
    @name = name or ''

  beginParsing: (parser) ->
    @trigger 'start-close-tag', parser

  doneParsing: (parser) ->
    @parsed = true
    @trigger 'end-close-tag close-tag node', parser

  trigger: (events, parser) ->
    parser.trigger events, [this]

  toElement: ->
    new Element @name

module.exports = CloseTag
