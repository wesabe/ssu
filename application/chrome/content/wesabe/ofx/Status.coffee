# Helper class to contain status messages from the OFX response.
wesabe.provide 'ofx.Status',
class Status
  constructor: (@code, @status, @message) ->

  isSuccess: ->
    if @code != "0" && @code != "1"
      false
    else
      true

  isError: ->
    !@isSuccess()

  isGeneralError: ->
    @code == '2000'

  isAuthenticationError: ->
    @code == '15500'

  isAuthorizationError: ->
    @code == '15000' || @code == '15502'

  isUnknownError: ->
    @isError() &&
    !@isGeneralError() &&
    !@isAuthenticationError() &&
    !@isAuthorizationError()

wesabe.ready 'wesabe.util.privacy', ->
  wesabe.util.privacy.registerTaintWrapper
    detector: (o) -> wesabe.is(o, wesabe.ofx.Status)
    getters: ["code", "status", "message"]
