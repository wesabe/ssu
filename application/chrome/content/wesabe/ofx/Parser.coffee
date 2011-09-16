XmlParser = require 'xml/Parser'
Parser    = require 'util/Parser'
event     = require 'util/event'

class OfxParser
  parse: (ofx) ->
    hparser = @parser = new Parser()

    event.forward hparser, this

    noop = ->
    quit = -> false

    headers = []
    currentHeader = null

    state =
      # first character
      start: (p) ->
        currentHeader =
          name: ''
          value: ''

        headers.push currentHeader
        state.name p

      # subsequent characters
      name: (p) ->
        currentHeader.name += p
        hparser.tokens =
          '[a-zA-Z0-9]': state.name
          ':': state.prevalue

      # :
      prevalue: ->
        hparser.tokens =
          '[^\\r\\n]': state.value
          '[\\r\\n]': state.end

      # characters in value
      value: (p) ->
        currentHeader.value += p

      # newline
      end: ->
        currentHeader = null
        hparser.tokens =
          '\\s': noop
          '[a-zA-Z]': state.start
          '<': quit

    hparser.tokens =
      '[a-zA-Z]': state.start
      '\\s': noop
      '<': quit

    hparser.parse ofx
    delete @parser
    @offset = hparser.offset-1 # put the "<" we read back in the buffer

    return headers

  stop: ->
    @parser.stop() if @parser


module.exports = OfxParser
