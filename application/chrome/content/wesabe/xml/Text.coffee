{_inspectString} = require 'util'
Colorizer        = require 'util/Colorizer'

class Text
  constructor: (text) ->
    @text = text or ''

  @::__defineGetter__ 'nodeValue', ->
    @text

  beginParsing: (parser) ->
    @trigger 'start-text', parser

  doneParsing: (parser) ->
    @parsed = true
    @trigger 'end-text text node', parser

  trigger: (events, parser) ->
    parser.trigger events, [this]

  inspect: (refs, color, tainted) ->
    s = new Colorizer()
    s.disabled = !color

    s.reset()
     .print(_inspectString @text, color, tainted)
     .reset()
     .toString()

module.exports = Text
