regexp = require 'lang/regexp'

# Public: Provides a means to handle HTTP requests by method and path.
class Router
  constructor: ->
    @routes = []

  # Public: Routes a request to an appropriate handler, if any.
  #
  # request - an object with 'method' and 'url' properties
  #
  # Examples
  #
  #   router.route method: 'GET', url: '/login'
  #   # => true
  #
  # Returns true if the request was handled, false otherwise.
  route: (request) ->
    routeAndMatch = @_routeAndMatchForRequest(request)
    routeAndMatch?.route.callback(routeAndMatch.match)

    return routeAndMatch isnt null

  # Public: Matches the incoming request against the existing routes in this
  # router.  This will only return interesting data if the matching route uses
  # placeholders.
  #
  # request - an object with 'method' and 'url' properties
  #
  # Examples
  #
  #   router.map 'GET', '/login', ->
  #   router.map 'GET', '/u/:username', ->
  #
  #   router.match method: 'GET', url: '/login'
  #   # => {}
  #
  #   router.match method: 'GET', url: '/u/eventualbuddha'
  #   # => {username: 'eventualbuddha'}
  #
  # Returns the match params for the given request or null if no routes matched
  # the request.
  match: (request) ->
    @_routeAndMatchForRequest(request)?.match

  # Internal: Gets a matching Route and the match data for a given request.
  _routeAndMatchForRequest: (request) ->
    for route in @routes
      match = route.match(request)
      return {route, match} if match

    return null

  # Public: Declares a new route.
  #
  # method - a String containing the HTTP verb to match (e.g. 'GET')
  # path - a String containing the HTTP path to match (e.g. '/login')
  # callback - the Function to call when the new route matches
  #
  # Examples
  #
  #   router.map 'GET', '/login', -> console.log('user is on the login page')
  #
  # Returns nothing.
  map: (method, path, callback) ->
    @routes.push new Route(method, path, callback)
    return null


# Internal: Represents an HTTP method and path plus callback.
class Route
  constructor: (@method, @path, @callback) ->
    @_placeholders = []
    matcher = ''
    remaining = @path

    while (colon = remaining.indexOf(':')) > 0
      before = remaining.slice(0, colon)
      placeholderAndAfter = remaining.slice(colon+1)
      placeholder = placeholderAndAfter.match(/^[_a-z0-9]+/i)?[0]
      remaining = placeholderAndAfter.slice(placeholder.length)

      matcher += regexp.escape(before) + '([^/.]+)'
      @_placeholders.push placeholder

    @_matcher = new RegExp(matcher)

  # Internal: Determines whether this route matches the request.
  #
  # request - an object with 'method' and 'url' properties
  #
  # Examples
  #
  #   route = new Route 'GET', '/login', ->
  #
  #   route.match method: 'POST', url: '/login'
  #   # => null
  #
  #   route.match method: 'GET', url: '/login'
  #   # => {}
  #
  #
  #   route = new Route 'GET', '/downloads/:name.:format', ->
  #
  #   route.match method 'GET', '/downloads/people.txt'
  #   # => {name: 'people', format: 'txt'}
  #
  match: (request) ->
    params = {}

    if @_placeholders.length is 0
      if request.method isnt @method or request.url isnt @path
        params = null
    else
      if values = @_matcher.exec(request.url)
        for placeholder, i in @_placeholders
          params[placeholder] = values[i+1]
      else
        params = null

    return params

  contentForInspect: ->
    {@method, @path}

module.exports = Router
