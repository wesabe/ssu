wesabe.require 'io.StreamListener'

{trigger} = require 'util/event'

sharedContentListener = null

class ContentListener
  @__defineGetter__ 'sharedInstance', ->
    sharedContentListener ||= new this()

  init: (contentWin, contentType) ->
    wesabe.debug("ContentListener#init(contentWin=#{contentWin}, contentType=#{contentType})")

    @contentWin = contentWin
    @contentType = contentType
    uriLoader = Components.classes["@mozilla.org/uriloader;1"].getService(Components.interfaces.nsIURILoader)
    uriLoader.registerContentListener(this)

  close: ->
    uriLoader = Components.classes["@mozilla.org/uriloader;1"].getService(Components.interfaces.nsIURILoader)
    uriLoader.unRegisterContentListener(this)

  QueryInterface: (iid) ->
    if iid.equals(Components.interfaces.nsIURIContentListener) ||
       iid.equals(Components.interfaces.nsISupportsWeakReference) ||
       iid.equals(Components.interfaces.nsISupports)
          return this

    throw Components.results.NS_NOINTERFACE

  onStartURIOpen: (uri) ->
    wesabe.debug("onStartURIOpen ", uri)
    return false

  doContent: (contentType, isContentPreferred, request, contentHandler) ->
    tryCatch "ContentListener#doContent(contentType=#{contentType})", (log) =>
      contentHandler.value = new wesabe.io.StreamListener((
        (data) =>
          filename = @suggestedFilenameForRequest(request)
          log.debug("got some data (filename=#{filename})")
          trigger this, 'after-receive', [data, filename]
        ), contentType)

    return false

  suggestedFilenameForRequest: (request) ->
    httpChannel = request.QueryInterface(Components.interfaces.nsIHttpChannel)

    try
      header = httpChannel.getResponseHeader('X-SSU-Content-Disposition')
      wesabe.debug('X-SSU-Content-Disposition header = ', header)
      match = header.match(/filename="([^"]+)"/i)
      return match?[1]
    catch err
      wesabe.debug "suggestedFilenameForRequest error: #{err}"

      httpChannel.visitResponseHeaders
        visitHeader: (key, value) -> wesabe.debug "HEADER: #{key}=#{value}"

      match = httpChannel.URI?.spec?.match(/.+\/([^\/\?]+)/)
      return match?[1]

  isPreferred: (contentType, desiredContentType) ->
    @contentType is contentType

  canHandleContent: (contentType, isContentPreferred, desiredContentType) ->
    @contentType is contentType

  GetWeakReference: ->
    this


module.exports = ContentListener
