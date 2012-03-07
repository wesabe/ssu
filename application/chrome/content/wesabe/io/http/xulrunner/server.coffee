RequestParser = require 'io/http/request/Parser'

STATUS_CODES =
  200: 'OK'
  201: 'Created'
  202: 'Accepted'
  204: 'No Content'
  301: 'Moved Permanently'
  302: 'Moved Temporarily'
  304: 'Not Modified'
  400: 'Bad Request'
  401: 'Unauthorized'
  403: 'Forbidden'
  404: 'Not Found'
  500: 'Internal Server Error'
  501: 'Not Implemented'
  502: 'Bad Gateway'
  503: 'Service Unavailable'

class HttpServer
  listen: (port, callback) ->
    socket = Cc['@mozilla.org/network/server-socket;1'].createInstance(Ci.nsIServerSocket)
    socket.init port, true, -1
    socket.asyncListen
      onSocketAccepted: (_, transport) ->
        outstream = transport.openOutputStream(Ci.nsITransport.OPEN_BLOCKING, 0, 0)
        stream    = transport.openInputStream(0, 0, 0)
        instream  = Cc['@mozilla.org/scriptableinputstream;1'].createInstance(Ci.nsIScriptableInputStream)
        instream.init stream

        pump = Cc['@mozilla.org/network/input-stream-pump;1'].createInstance(Ci.nsIInputStreamPump)
        pump.init stream, -1, -1, 0, 0, false

        http = null
        data = null

        onStartRequest = ->
          http = {}
          data = ''

        onStopRequest = ->
          http = null
          data = null
          outstream?.close()

        onDataAvailable = (request, context, inputStream, offset, count) ->
          data += instream.read count

          if contentLengthMatch = /\bContent-Length:\s*(\d+)\r\n/i.exec data
            contentLength = parseInt(contentLengthMatch[1], 10)
            endOfHeaders = data.indexOf('\r\n\r\n')

            if endOfHeaders > 0
              if endOfHeaders + 4 + contentLength is data.length
                instream.close()
                processHttpRequest()
                http = null
                data = null

        processHttpRequest = ->
          request = RequestParser.parse data

          write = (data) ->
            outstream.write data, data.length

          writeln = (data) ->
            write "#{data}\r\n"

          headWritten = false
          response =
            statusCode: 200
            headers: {}
            write: (data) ->
              if not headWritten
                writeln "HTTP/1.0 #{@statusCode} #{STATUS_CODES[@statusCode]}"
                writeln "#{name}: #{value}" for own name, value of @headers
                writeln ''
              write data
            close: ->
              outstream.close()
              outstream = null

          callback request, response

        pump.asyncRead {onStartRequest, onStopRequest, onDataAvailable}, null

module.exports = HttpServer
