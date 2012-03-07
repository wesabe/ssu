Parser = require 'io/http/request/Parser'

emptyGET = 'GET /login?return_to=%2fhome HTTP/1.0\r\n\r\n'
simpleGET = 'GET /signup\r\n\r\n'
withHeaders = 'GET / HTTP/1.0\r\nHost: example.com\r\nAccept: text/plain\r\nUser-Agent: curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5\r\n\r\n'

basicPOST = 'POST /items HTTP/1.0\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: 7\r\n\r\nfoo=bar'

describe 'io/http/request/Parser', ->
  describe 'parsing an HTTP/1.0 GET request without headers', ->
    request = null

    beforeEach ->
      request = Parser.parse emptyGET

    it 'parses the method correctly', ->
      expect(request.method).toEqual('GET')

    it 'parses the url correctly', ->
      expect(request.url).toEqual('/login?return_to=%2fhome')

    it 'parses the http version correctly', ->
      expect(request.httpVersion).toEqual(1.0)

    it 'has an empty list of headers', ->
      expect(request.headers).toEqual([])

  describe 'parsing an HTTP/0.9 simple GET request', ->
    request = null

    beforeEach ->
      request = Parser.parse simpleGET

    it 'parses the method correctly', ->
      expect(request.method).toEqual('GET')

    it 'parses the url correctly', ->
      expect(request.url).toEqual('/signup')

    it 'parses the http version correctly', ->
      expect(request.httpVersion).toEqual(0.9)

  describe 'parsing an HTTP/1.0 GET with headers', ->
    request = null

    beforeEach ->
      request = Parser.parse withHeaders

    it 'parses simple headers correctly', ->
      expect(request.headers.Host).toEqual('example.com')
      expect(request.headers.Accept).toEqual('text/plain')

    it 'parses headers with spaces correctly', ->
      expect(request.headers['User-Agent']).toEqual('curl/7.21.4 (universal-apple-darwin11.0) libcurl/7.21.4 OpenSSL/0.9.8r zlib/1.2.5')

  describe 'parsing an HTTP/1.0 POST', ->
    request = null

    beforeEach ->
      request = Parser.parse basicPOST

    it 'parses the method correctly', ->
      expect(request.method).toEqual('POST')

    it 'parses the body correctly', ->
      expect(request.body).toEqual('foo=bar')
