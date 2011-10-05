crypto  = require 'crypto'
type    = require 'lang/type'
array   = require 'lang/array'
inspect = require 'util/inspect'

Point = require 'canvas/geometry/Point'

class ImageData
  constructor: (@rect, @data) ->

  getDataAtPoint: (point) ->
    if not @rect.contains(point)
      throw new Error "Cannot get image data for out-of-bounds point (point=#{inspect point}, rect=#{inspect @rect})"

    offset = (point.x + @rect.size.width * point.y) * 4
    return @data.slice offset, offset + 4

  withRect: (rect) ->
    data = []

    for y in [rect.top...rect.bottom]
      for x in [rect.left...rect.right]
        data = data.concat @getDataAtPoint(new Point(x, y))

    return new @constructor rect, data

  @::__defineGetter__ 'signature', ->
    crypto.createHash('md5').update(object).digest('hex')

  findPoint: (options) ->
    p = options.start
    bounds = options.bounds or @rect

    while bounds.contains(p)
      if options.color
        return p if @pointHasColor p, options.color

      else if type.isFunction options.test
        return p if options.test p

      # move p according to the step option
      p = new Point p.x + options.step.width, p.y + options.step.height

    return null

  pointHasColor: (p, color) ->
    array.equal @getDataAtPoint(p), color

  findPoints: (options) ->
    bounds = options.bounds or @rect
    points = []
    p0     = bounds.origin.withOffset(bounds.size) # bottom-right
    p      = new Point p0.x, p0.y

    while p.y >= bounds.top
      while p.x >= bounds.left
        points.push p.clone() if options.test p
        p.x--
      p.x = p0.x
      p.y--

    return points


module.exports = ImageData
