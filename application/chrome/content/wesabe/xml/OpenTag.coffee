wesabe.provide('xml.OpenTag')

class wesabe.xml.OpenTag
  constructor: (name) ->
    @name = name || ''

  beginParsing: (parser) ->
    @trigger('start-open-tag', parser)

  doneParsing: (parser) ->
    @parsed = true
    @trigger('end-open-tag open-tag node', parser)

  trigger: (events, parser) ->
    parser.trigger(events, [this])

  toElement: ->
    new wesabe.xml.Element(@name, @selfclosing)
