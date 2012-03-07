http = require 'http'

exports.create = ->
  callback = null
  server = http.createServer (request, response) ->
    callback? request, response

  listen: (port, fn) ->
    callback = fn
    server.listen port