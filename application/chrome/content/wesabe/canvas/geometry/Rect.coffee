Point     = require 'canvas/geometry/Point'
Size      = require 'canvas/geometry/Size'
Colorizer = require 'util/Colorizer'

class Rect
  constructor: (@origin, @size) ->

  contains: (point) ->
    (@origin.x <= point.x) and
    (@origin.y <= point.y) and
    (point.x <= @origin.x + @size.width) and
    (point.y <= @origin.y + @size.height)

  @::__defineGetter__ 'width', ->
    @size.width

  @::__defineGetter__ 'height', ->
    @size.height

  @::__defineGetter__ 'left', ->
    @origin.x

  @::__defineGetter__ 'top', ->
    @origin.y

  @::__defineGetter__ 'right', ->
    @origin.x + @size.width

  @::__defineGetter__ 'bottom', ->
    @origin.y + @size.height

  @::__defineGetter__ 'center', ->
    new Point @origin.x + @size.width / 2, @origin.y + @size.height / 2

  @make: (x, y, w, h) ->
    new this new Point(x, y), new Size(w, h)

  @fromPoints: (p1, p2) ->
    origin = new Point Math.min(p1.x, p2.x), Math.min(p1.y, p2.y)
    size = new Size Math.max(p1.x, p2.x) - origin.x, Math.max(p1.y, p2.y) - origin.y

    new this origin, size

  @__defineGetter__ 'ZeroRect', ->
    @make 0, 0, 0, 0

  inspect: (refs, color, tainted) ->
    s = new Colorizer()
    s.disabled = !color
    s
      .yellow('#<')
      .bold(@constructor?.__module__?.name or 'Object')
      .print(' ')
      .yellow('{')
      .print(@left)
      .print(', ')
      .print(@top)
      .print(', ')
      .print(@width)
      .print(', ')
      .print(@height)
      .print('}')
      .yellow('>')
      .toString()


module.exports = Rect
