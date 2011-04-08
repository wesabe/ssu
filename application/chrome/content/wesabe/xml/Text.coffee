wesabe.provide('xml.Text')

class wesabe.xml.Text
  constructor: (text) ->
    @text = text || ''

  beginParsing: (parser) ->
    @trigger('start-text', parser)

  doneParsing: (parser) ->
    @parsed = true
    @trigger('end-text text node', parser)

  trigger: (events, parser) ->
    parser.trigger(events, [this])

  inspect: (refs, color, tainted) ->
    s = new wesabe.util.Colorizer()
    s.disabled = !color

    s.reset()
     .print(wesabe.util._inspectString(@text, color, tainted))
     .reset()
     .toString();
