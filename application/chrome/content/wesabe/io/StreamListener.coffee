class StreamListener
  constructor: (@callbackFunc, @contentType) ->

  mData: ""

  onStartRequest: (aRequest, aContext) ->
    @mData = ""

  onDataAvailable: (aRequest, aContext, aStream, aSourceOffset, aLength) ->
    bstream = Cc["@mozilla.org/binaryinputstream;1"].createInstance(Ci.nsIBinaryInputStream)
    bstream.setInputStream(aStream)
    @mData += bstream.readBytes(aLength)

  onStopRequest: (aRequest, aContext, aStatus) ->
    if Components.isSuccessCode(aStatus)
      @callbackFunc @mData, @contentType
    else
      @callbackFunc "request failed"

  onChannelRedirect: (aOldChannel, aNewChannel, aFlags) ->
    gChannel = aNewChannel

  getInterface: (aIID) ->
      try
        @QueryInterface aIID
      catch e
        throw Components.results.NS_NOINTERFACE

  onProgress: (aRequest, aContext, aProgress, aProgressMax) ->
  onStatus: (aRequest, aContext, aStatus, aStatusArg) ->
  onRedirect: (aOldChannel, aNewChannel) ->

  QueryInterface: (aIID) ->
    if aIID.equals(Ci.nsISupports) or
       aIID.equals(Ci.nsIInterfaceRequestor) or
       aIID.equals(Ci.nsIChannelEventSink) or
       aIID.equals(Ci.nsIProgressEventSink) or
       aIID.equals(Ci.nsIHttpEventSink) or
       aIID.equals(Ci.nsIStreamListener)
        return this

    throw Components.results.NS_NOINTERFACE


module.exports = StreamListener
