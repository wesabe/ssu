Colorizer = require 'util/Colorizer'

class Point
  constructor: (@x, @y) ->

  @__defineGetter__ 'ZeroPoint', ->
    new this 0, 0

  @::__defineGetter__ 'nearestPixel',
    new @constructor Math.round(@x), Math.round(@y)

  withOffset: (x, y) ->
    if not y?
      y = x.y or x.height
      x = x.x or x.width

    new @constructor @x + x, @y + y

  clone: ->
    new @constructor @x, @y

  inspect: (refs, color, tainted) ->
    s = new Colorizer()
    s.disabled = !color
    s
      .yellow('#<')
      .bold(@constructor?.__module__?.name || 'Object')
      .print(' ')
      .yellow('{')
      .print(@x)
      .print(', ')
      .print(@y)
      .yellow('}')
      .yellow('>')
      .toString()


module.exports = Point
