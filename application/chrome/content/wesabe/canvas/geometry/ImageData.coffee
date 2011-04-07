wesabe.provide('canvas.geometry.ImageData')
wesabe.require('crypto')

class wesabe.canvas.geometry.ImageData
  constructor: (rect, data) ->
    @rect = rect
    @data = data

  getDataAtPoint: (point) ->
    if !@rect.contains(point)
      throw new Error("Cannot get image data for out-of-bounds point (point=#{wesabe.util.inspect(point)}, rect=#{wesabe.util.inspect(@rect)})")

    offset = (point.x + @rect.size.width * point.y) * 4
    return @data.slice(offset, offset + 4)

  withRect: (rect) ->
    data = []

    for y in [rect.top...rect.bottom]
      for x in [rect.left...rect.right]
        data = data.concat(@getDataAtPoint(new wesabe.canvas.geometry.Point(x, y)))

    return new @constructor(rect, data)

  this::__defineGetter__ 'signature', ->
    wesabe.crypto.md5(@data)

  findPoint: (options) ->
    p = options.start
    bounds = options.bounds || @rect

    while bounds.contains(p)
      if options.color
        if @pointHasColor(p, options.color)
          return p
      else if wesabe.isFunction(options.test)
        if options.test(p)
          return p

      # move p according to the step option
      p = new wesabe.canvas.geometry.Point(p.x + options.step.width, p.y + options.step.height)

    return null

  pointHasColor: (p, color) ->
    wesabe.lang.array.equal(@getDataAtPoint(p), color)

  findPoints: (options) ->
    bounds = options.bounds || @rect
    points = []
    p0     = bounds.origin.withOffset(bounds.size) # bottom-right
    p      = new wesabe.canvas.geometry.Point(p0.x, p0.y)

    while p.y >= bounds.top
      while p.x >= bounds.left
        points.push(p.clone()) if options.test(p)
        p.x--
      p.x = p0.x
      p.y--

    return points
