wesabe.provide('ofx.Document')
wesabe.require('ofx.Parser')
wesabe.require('xml.Document')

class wesabe.ofx.Document extends wesabe.xml.Document
  #
  # Parse an OFX document, including headers.
  #
  parse: (ofx, verboten) ->
    parser = new wesabe.ofx.Parser()

    try
      @headers = parser.parse(ofx)
      super(ofx.slice(parser.offset), verboten)
    catch e
      wesabe.error('ofx.Document#parse: ', e)
