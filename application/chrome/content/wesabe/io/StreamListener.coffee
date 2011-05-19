wesabe.provide('io.StreamListener')

class wesabe.io.StreamListener
  constructor: (callbackFunc, contentType) ->
    @callbackFunc = callbackFunc
    @contentType = contentType

  mData: ""

  onStartRequest: (aRequest, aContext) ->
    @mData = ""

  onDataAvailable: (aRequest, aContext, aStream, aSourceOffset, aLength) ->
    scriptableInputStream = Cc["@mozilla.org/scriptableinputstream;1"].createInstance(Ci.nsIScriptableInputStream)
    scriptableInputStream.init(aStream)
    @mData += scriptableInputStream.read(aLength)

  onStopRequest: (aRequest, aContext, aStatus) ->
    if Components.isSuccessCode(aStatus)
      @callbackFunc(@mData, @contentType)
    else
      @callbackFunc("request failed")

  onChannelRedirect: (aOldChannel, aNewChannel, aFlags) ->
    gChannel = aNewChannel

  getInterface: (aIID) ->
      try
        this.QueryInterface(aIID)
      catch e
        throw Components.results.NS_NOINTERFACE

  onProgress: (aRequest, aContext, aProgress, aProgressMax) ->
  onStatus: (aRequest, aContext, aStatus, aStatusArg) ->
  onRedirect: (aOldChannel, aNewChannel) ->

  QueryInterface: (aIID) ->
    if aIID.equals(Ci.nsISupports) ||
       aIID.equals(Ci.nsIInterfaceRequestor) ||
       aIID.equals(Ci.nsIChannelEventSink) ||
       aIID.equals(Ci.nsIProgressEventSink) ||
       aIID.equals(Ci.nsIHttpEventSink) ||
       aIID.equals(Ci.nsIStreamListener)
        return this

    throw Components.results.NS_NOINTERFACE
