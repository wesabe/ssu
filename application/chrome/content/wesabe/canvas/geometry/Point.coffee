wesabe.provide('canvas.geometry.Point')

class wesabe.canvas.geometry.Point
  constructor: (x, y) ->
    @x = x
    @y = y

  @__defineGetter__ 'ZeroPoint', ->
    new this(0, 0)

  this::__defineGetter__ 'nearestPixel',
    new this.constructor(Math.round(@x, @y))

  withOffset: (x, y) ->
    if not y?
      y = x.y || x.height
      x = x.x || x.width

    new this.constructor(@x + x, @y + y)

  clone: ->
    new this.constructor(@x, @y)

  inspect: (refs, color, tainted) ->
    s = new wesabe.util.Colorizer()
    s.disabled = !color
    s
      .yellow('#<')
      .bold(this.constructor?.__module__?.name || 'Object')
      .print(' ')
      .yellow('{')
      .print(@x)
      .print(', ')
      .print(@y)
      .yellow('}')
      .yellow('>')
      .toString()
