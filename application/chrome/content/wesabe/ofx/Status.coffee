# Helper class to contain status messages from the OFX response.

type = require 'util/type'

class Status
  constructor: (@code, @status, @message) ->

  isSuccess: ->
    @code in ["0", "1"]

  isError: ->
    not @isSuccess()

  isGeneralError: ->
    @code is '2000'

  isAuthenticationError: ->
    @code is '15500'

  isAuthorizationError: ->
    @code is '15000' or @code is '15502'

  isUnknownError: ->
    @isError() and
    not @isGeneralError() and
    not @isAuthenticationError() and
    not @isAuthorizationError()

wesabe.util.privacy.registerTaintWrapper
  detector: (o) -> type.is(o, wesabe.ofx.Status)
  getters: ["code", "status", "message"]


module.exports = Status
