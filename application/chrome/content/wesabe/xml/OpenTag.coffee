Element = require 'xml/Element'

class OpenTag
  constructor: (name) ->
    @name = name or ''

  beginParsing: (parser) ->
    @trigger 'start-open-tag', parser

  doneParsing: (parser) ->
    @parsed = true
    @trigger 'end-open-tag open-tag node', parser

  trigger: (events, parser) ->
    parser.trigger events, [this]

  toElement: ->
    new Element @name, @selfclosing

module.exports = OpenTag
