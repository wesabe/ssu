Colorizer = require 'util/Colorizer'

class Size
  constructor: (@width, @height) ->

  inspect: (refs, color, tainted) ->
    s = new Colorizer()
    s.disabled = !color
    return s
      .yellow('#<')
      .bold(@constructor?.__module__?.name or 'Object')
      .print(' ')
      .yellow('{')
      .print(@width)
      .print(', ')
      .print(@height)
      .yellow('}')
      .yellow('>')
      .toString()


module.exports = Size
