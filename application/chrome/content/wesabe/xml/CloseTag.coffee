wesabe.provide('xml.CloseTag')

class wesabe.xml.CloseTag
  constructor: (name) ->
    @name = name || ''

  beginParsing: (parser) ->
    @trigger('start-close-tag', parser)

  doneParsing: (parser) ->
    @parsed = true
    @trigger('end-close-tag close-tag node', parser)

  trigger: (events, parser) ->
    parser.trigger(events, [this])

  toElement: ->
    new wesabe.xml.Element(@name)
