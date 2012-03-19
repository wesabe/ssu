Router = require 'io/http/Router'
type   = require 'lang/type'
{trim} = require 'lang/string'
TYPES  = require 'io/http/MimeTypes'

Colorizer = require 'util/Colorizer'

if phantom?
  HttpServer = require 'io/http/phantom/server'
else if Cc?
  HttpServer = require 'io/http/xulrunner/server'
else
  HttpServer = require 'io/http/node/server'


class Server
  constructor: (portRange) ->
    if type.isArray portRange
      ports = [portRange[0]..portRange[1]]
    else
      ports = [portRange]

    @router = new Router
    @server = new HttpServer


    # provide a simple test endpoint that just echos the request data
    @post '/_echo', ->
      @deliver @request.json


    for port in portRange
      try
        @server.listen port, (request, response) =>
          @_dispatch new Request(request), response

        @port = port
        return
      catch e

    if type.isArray portRange
      throw new Error "Unable to bind to port #{portRange}"
    else
      throw new Error "Unable to bind to any port in #{portRange[0]}..#{portRange[1]}"

  map: (method, path, callback) ->
    @router.map method, path, (@params) =>
      callback.call @
      delete @params

  get: (path, callback) ->
    @map 'GET', path, callback

  post: (path, callback) ->
    @map 'POST', path, callback

  put: (path, callback) ->
    @map 'PUT', path, callback

  delete: (path, callback) ->
    @map 'DELETE', path, callback


  # Public: Sends data as the response body to the client.
  #
  # data - an object to send as JSON to the client
  # options - used to define additional response parameters;
  #           status      - HTTP status code to respond with (default: 200)
  #           contentType - HTTP response content type
  #                         (default: application/octet-stream for String data,
  #                         application/json for Object data)
  #
  # Returns nothing.
  deliver: (data, options={}) ->
    options =
      status: options.status or 200
      contentType: options.contentType

    if not data?
      throw new NotFoundError
    else if /Error$/.test data.constructor.name
      throw new InternalServerError(data)
    else if type.isString data
      @response.statusCode = options.status
      @response.headers['Content-Type'] ||= options.contentType or
                                            'application/octet-stream'
      @response.write data
    else
      @response.statusCode = options.status
      @response.headers['Content-Type'] ||= options.contentType or 'application/json'
      @response.write JSON.stringify(data)

    @response.close()

  # Internal: Dispatches a request to the appropriate handler.
  _dispatch: (@request, @response) ->
    logger.info "#{Colorizer.magenta @request.method} #{Colorizer.green @request.url}"

    try
      if not @router.route @request
        throw new NotFoundError "No route matches #{@request.url}"
    catch ex
      if 'statusCode' not of ex
        logger.error "Error while serving request:\n\n", ex
        ex = new InternalServerError ex
      responded = no

      @response.statusCode = ex.statusCode
      for type in @request.accepts when not type.isGlobal
        if body = ex.responseForType type
          @response.write body
          responded = yes

      if responded is no
        @response.write ex.responseForType TYPES.HTML

      @response.close()

    statusColor = if @response.statusCode < 300
                    'green'
                  else if @response.statusCode < 400
                    'cyan'
                  else if @response.statusCode < 500
                    'yellow'
                  else
                    'red'

    logger.info "#{Colorizer[statusColor] @response.statusCode} #{Colorizer.green @request.url}"

    delete @request
    delete @response

  contentForInspect: ->
    {@port}


class Request
  constructor: (data) ->
    @method      = data.method
    @url         = data.url
    @headers     = data.headers
    @httpVersion = data.httpVersion
    @body        = data.body

  @::__defineGetter__ 'json', ->
    @_json ||= @body and JSON.parse(@body)

  @::__defineGetter__ 'accepts', ->
    return [] unless 'Accept' of @headers

    @_accepts ||= (=>
      [accept,] = @headers['Accept'].split(';')
      TYPES.search(trim type) for type in accept.split(',')
    )()

  contentForInspect: ->
    {@method, @url, @headers, @httpVersion, @body}

class HttpError extends Error
  constructor: (wrappedError) ->
    if type.isString wrappedError
      @message = wrappedError
      wrappedError = null
    else if wrappedError?.message?
      @message = wrappedError.message

    @errorType = (wrappedError or @).constructor.name

  responseForType: (mimeType) ->
    switch mimeType
      when TYPES.JSON
        JSON.stringify(
          error:
            type: @errorType
            message: @message
        )
      when TYPES.HTML
        """
        <html>
          <head><title>#{@statusCode} #{@statusString}</title></head>
          <body>
            <h1>#{@statusCode} #{@statusString}</h1>
            <pre>#{@errorType}: #{@message}</pre>
          </body>
        </html>
        """
      else
        null

class InternalServerError extends HttpError
  statusCode: 500
  statusString: 'Internal Server Error'

class NotFoundError extends HttpError
  statusCode: 404
  statusString: 'Not Found'

Server.NotFoundError = NotFoundError
Server.InternalServerError = InternalServerError

module.exports = Server
