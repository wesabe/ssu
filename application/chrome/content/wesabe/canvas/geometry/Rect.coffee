wesabe.provide('canvas.geometry.Rect')

class wesabe.canvas.geometry.Rect
  constructor: (origin, size) ->
    @origin = origin
    @size = size

  contains: (point) ->
    (@origin.x <= point.x) &&
    (@origin.y <= point.y) &&
    (point.x <= @origin.x + @size.width) &&
    (point.y <= @origin.y + @size.height)

  this::__defineGetter__ 'width', ->
    @size.width

  this::__defineGetter__ 'height', ->
    @size.height

  this::__defineGetter__ 'left', ->
    @origin.x

  this::__defineGetter__ 'top', ->
    @origin.y

  this::__defineGetter__ 'right', ->
    @origin.x + @size.width

  this::__defineGetter__ 'bottom', ->
    @origin.y + @size.height

  this::__defineGetter__ 'center', ->
    new wesabe.canvas.geometry.Point(@origin.x + @size.width / 2, @origin.y + @size.height / 2)

  @make: (x, y, w, h) ->
    new this(
      new wesabe.canvas.geometry.Point(x, y),
      new wesabe.canvas.geometry.Size(w, h))

  @fromPoints: (p1, p2) ->
    origin = new wesabe.canvas.geometry.Point(
      Math.min(p1.x, p2.x),
      Math.min(p1.y, p2.y))
    size = new wesabe.canvas.geometry.Size(
      Math.max(p1.x, p2.x) - origin.x,
      Math.max(p1.y, p2.y) - origin.y)

    new this(origin, size)

  @__defineGetter__ 'ZeroRect', ->
    @make(0, 0, 0, 0)

  inspect: (refs, color, tainted) ->
    s = new wesabe.util.Colorizer()
    s.disabled = !color
    s
      .yellow('#<')
      .bold(@constructor?.__module__?.name || 'Object')
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
