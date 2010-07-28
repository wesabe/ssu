wesabe.provide('io.StreamListener');

wesabe.io.StreamListener = function(callbackFunc, contentType) {
  this.callbackFunc = callbackFunc;
  this.contentType = contentType;
}

wesabe.io.StreamListener.prototype = {
  mData: "",
  onStartRequest: function (aRequest, aContext) {
    this.mData = "";
  },
  onDataAvailable: function (aRequest, aContext, aStream, aSourceOffset, aLength) {
    var scriptableInputStream = 
      Components.classes["@mozilla.org/scriptableinputstream;1"]
        .createInstance(Components.interfaces.nsIScriptableInputStream);
    scriptableInputStream.init(aStream);
    this.mData += scriptableInputStream.read(aLength);
  },
  onStopRequest: function (aRequest, aContext, aStatus) {
    if (Components.isSuccessCode(aStatus)) {
      this.callbackFunc(this.mData, this.contentType);
    }
    else {
      this.callbackFunc("request failed");    
    }
  },
  onChannelRedirect: function (aOldChannel, aNewChannel, aFlags) {
    gChannel = aNewChannel;
  },
  getInterface: function (aIID) {
      try {
        return this.QueryInterface(aIID);
      } catch (e) {
        throw Components.results.NS_NOINTERFACE;
      }
  },
  onProgress : function (aRequest, aContext, aProgress, aProgressMax) { },
  onStatus : function (aRequest, aContext, aStatus, aStatusArg) { },
  onRedirect : function (aOldChannel, aNewChannel) { },
  QueryInterface : function(aIID) {
    if (aIID.equals(Components.interfaces.nsISupports) ||
        aIID.equals(Components.interfaces.nsIInterfaceRequestor) ||
        aIID.equals(Components.interfaces.nsIChannelEventSink) || 
        aIID.equals(Components.interfaces.nsIProgressEventSink) ||
        aIID.equals(Components.interfaces.nsIHttpEventSink) ||
        aIID.equals(Components.interfaces.nsIStreamListener))
        return this;
    throw Components.results.NS_NOINTERFACE;
  }
};
