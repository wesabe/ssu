wesabe.provide('canvas.geometry.Size')

class wesabe.canvas.geometry.Size
  constructor: (width, height) ->
    @width = width
    @height = height

  inspect: (refs, color, tainted) ->
    s = new wesabe.util.Colorizer()
    s.disabled = !color
    return s
      .yellow('#<')
      .bold(@constructor?.__module__?.name || 'Object')
      .print(' ')
      .yellow('{')
      .print(@width)
      .print(', ')
      .print(@height)
      .yellow('}')
      .yellow('>')
      .toString()
