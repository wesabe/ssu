wesabe.provide('io.ContentListener');
wesabe.require('logger.*');
wesabe.require('io.StreamListener');


wesabe.io.ContentListener = function() {};

wesabe.io.ContentListener.__defineGetter__('sharedInstance', function() {
  if (!wesabe.io.ContentListener._sharedInstance)
    wesabe.io.ContentListener._sharedInstance = new wesabe.io.ContentListener();
  return wesabe.io.ContentListener._sharedInstance;
});

wesabe.io.ContentListener.prototype.init = function(contentWin, contentType) {
  wesabe.debug('ContentListener#init(contentWin=' + 
                contentWin + ', contentType=' + contentType + ')');
  
  this.contentWin = contentWin;
  this.contentType = contentType;
  var uriLoader = Components.classes["@mozilla.org/uriloader;1"].getService(Components.interfaces.nsIURILoader);
  uriLoader.registerContentListener(this);
};

wesabe.io.ContentListener.prototype.close = function() {
  var uriLoader = Components.classes["@mozilla.org/uriloader;1"].getService(Components.interfaces.nsIURILoader);
  uriLoader.unRegisterContentListener(this);
};

wesabe.io.ContentListener.prototype.QueryInterface = function(iid) {
  if (iid.equals(Components.interfaces.nsIURIContentListener) ||
      iid.equals(Components.interfaces.nsISupportsWeakReference) ||
      iid.equals(Components.interfaces.nsISupports))
        return this;
  throw Components.results.NS_NOINTERFACE;
};
  
wesabe.io.ContentListener.prototype.onStartURIOpen = function(uri) {
  wesabe.debug("onStartURIOpen ", uri);
  return false;
};

wesabe.io.ContentListener.prototype.doContent = function(contentType, isContentPreferred, request, contentHandler) {
  var self = this;
  wesabe.tryCatch('ContentListener#doContent(contentType=' + contentType + ')', function(log) {
    contentHandler.value = new wesabe.io.StreamListener(
      function(data){ log.debug('got some data'); wesabe.trigger(self, 'after-receive', [data]) }, contentType);
  });
  return false;
};

wesabe.io.ContentListener.prototype.isPreferred = function(contentType, desiredContentType) {
  return this.contentType == contentType;
};

wesabe.io.ContentListener.prototype.canHandleContent = function(contentType, isContentPreferred, desiredContentType) {
  return this.contentType == contentType;
};

wesabe.io.ContentListener.prototype.GetWeakReference = function() {
  return this;
};
