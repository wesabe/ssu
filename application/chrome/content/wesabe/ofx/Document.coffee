Parser      = require 'ofx/Parser'
XmlDocument = require 'xml/Document'

class OfxDocument extends XmlDocument
  #
  # Parse an OFX document, including headers.
  #
  parse: (ofx, verboten) ->
    parser = new Parser()

    try
      @headers = parser.parse ofx
      super ofx.slice(parser.offset), verboten
    catch e
      logger.error 'ofx.Document#parse: ', e


module.exports = OfxDocument
