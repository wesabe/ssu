Colorizer = require 'util/Colorizer'

class Point
  constructor: (@x, @y) ->

  @__defineGetter__ 'ZeroPoint', ->
    new @ 0, 0

  @::__defineGetter__ 'nearestPixel',
    new @constructor Math.round(@x), Math.round(@y)

  withOffset: (x, y) ->
    if not y?
      y = x.y or x.height
      x = x.x or x.width

    new @constructor @x + x, @y + y

  clone: ->
    new @constructor @x, @y


module.exports = Point
