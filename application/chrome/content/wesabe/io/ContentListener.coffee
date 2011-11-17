StreamListener = require 'io/StreamListener'

{EventEmitter} = require 'events2'
{tryThrow, tryCatch} = require 'util/try'

sharedContentListener = null

class ContentListener extends EventEmitter
  @__defineGetter__ 'sharedInstance', ->
    sharedContentListener ||= new this()

  init: (contentWin, contentType) ->
    logger.debug "ContentListener#init(contentWin=#{contentWin}, contentType=#{contentType})"

    @contentWin = contentWin
    @contentType = contentType
    uriLoader = Cc["@mozilla.org/uriloader;1"].getService(Ci.nsIURILoader)
    uriLoader.registerContentListener(this)

  close: ->
    uriLoader = Cc["@mozilla.org/uriloader;1"].getService(Ci.nsIURILoader)
    uriLoader.unRegisterContentListener(this)

  QueryInterface: (iid) ->
    if iid.equals(Ci.nsIURIContentListener) ||
       iid.equals(Ci.nsISupportsWeakReference) ||
       iid.equals(Ci.nsISupports)
          return this

    throw Components.results.NS_NOINTERFACE

  onStartURIOpen: (uri) ->
    logger.debug "onStartURIOpen(", uri, ")"
    return false

  doContent: (contentType, isContentPreferred, request, contentHandler) ->
    tryCatch "ContentListener#doContent(contentType=#{contentType})", (log) =>
      contentHandler.value = new StreamListener((
        (data) =>
          filename = @suggestedFilenameForRequest request
          originalContentType = @originalContentTypeForRequest request
          log.debug "got some data (filename=", filename, ", contentType=", originalContentType, ")"
          @emit 'after-receive', data, filename, originalContentType
        ), contentType)

    return false

  suggestedFilenameForRequest: (request) ->
    httpChannel = request.QueryInterface(Components.interfaces.nsIHttpChannel)

    try
      header = httpChannel.getResponseHeader('X-SSU-Content-Disposition')
      logger.debug 'X-SSU-Content-Disposition header = ', header
      match = header.match(/filename="([^"]+)"/i)
      return match?[1]
    catch err
      logger.debug "suggestedFilenameForRequest error: #{err}"

      httpChannel.visitResponseHeaders
        visitHeader: (key, value) -> logger.debug "HEADER: #{key}=#{value}"

      match = httpChannel.URI?.spec?.match(/.+\/([^\/\?]+)/)
      return match?[1]

  originalContentTypeForRequest: (request) ->
    httpChannel = request.QueryInterface(Components.interfaces.nsIHttpChannel)

    try
      header = httpChannel.getResponseHeader('X-SSU-Content-Type')
      logger.debug 'X-SSU-Content-Type header = ', header
      return header
    catch err
      logger.debug "originalContentTypeForRequest error: #{err}"
      return null

  isPreferred: (contentType, desiredContentType) ->
    @contentType is contentType

  canHandleContent: (contentType, isContentPreferred, desiredContentType) ->
    @contentType is contentType

  GetWeakReference: ->
    this


module.exports = ContentListener
