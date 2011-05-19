wesabe.provide('io.ContentListener')
wesabe.require('logger.*')
wesabe.require('io.StreamListener')

sharedContentListener = null

class wesabe.io.ContentListener
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

    throw Components.results.NS_NOINTERFACE;

  onStartURIOpen: (uri) ->
    wesabe.debug("onStartURIOpen ", uri)
    return false

  doContent: (contentType, isContentPreferred, request, contentHandler) ->
    wesabe.tryCatch "ContentListener#doContent(contentType=#{contentType})", (log) =>
      contentHandler.value = new wesabe.io.StreamListener((
        (data) =>
          log.debug('got some data')
          wesabe.trigger(this, 'after-receive', [data])
        ), contentType)

    return false

  isPreferred: (contentType, desiredContentType) ->
    @contentType == contentType

  canHandleContent: (contentType, isContentPreferred, desiredContentType) ->
    @contentType == contentType

  GetWeakReference: ->
    this
