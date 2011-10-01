(function() {
  var Cc, Ci, Cr, WESABE_LOGGER_CID, WESABE_LOGGER_CONTRACTID, WES_WUFF_LOG_TXT, WesabeLogger, WesabeLoggerFactory, WesabeLoggerModule, getDateStr, pad, wesLogFoutStream;
  var __slice = Array.prototype.slice;
  WESABE_LOGGER_CONTRACTID = "@wesabe.com/logger;1";
  WESABE_LOGGER_CID = Components.ID("{0e2843fd-9579-4ec3-9321-f27e2b3c3fbc}");
  WES_WUFF_LOG_TXT = "wuff_log.txt";
  Cc = Components.classes;
  Ci = Components.interfaces;
  Cr = Components.results;
  wesLogFoutStream = null;
  pad = function(n, c) {
    n = n.toString();
    while (!(n.length >= c)) {
      n = "0" + n;
    }
    return n;
  };
  getDateStr = function() {
    var d;
    d = new Date();
    return "" + (d.getFullYear()) + "." + (pad(d.getMonth() + 1, 2)) + "." + (pad(d.getDate(), 2)) + " " + (pad(d.getHours(), 2)) + ":" + (pad(d.getMinutes(), 2)) + ":" + (pad(d.getSeconds(), 2)) + ":" + (pad(d.getMilliseconds(), 3)) + " " + (pad(d.getTimezoneOffset() / 60, 2));
  };
  WesabeLogger = (function() {
    function WesabeLogger() {
      var file;
      try {
        this.mLog = Cc['@mozilla.org/consoleservice;1'].getService(Ci.nsIConsoleService);
        this.fout = Cc["@mozilla.org/network/file-output-stream;1"].createInstance(Ci.nsIFileOutputStream);
        wesLogFoutStream = this.fout;
        file = this.getLogFileByFileName(WES_WUFF_LOG_TXT);
        this.fout.init(file, 0x02 | 0x08 | 0x10, 0664, 0);
      } catch (ex) {
        dump("WesabeLogger error: " + ex.message + "\n");
      }
    }
    WesabeLogger.prototype.QueryInterface = function(iid) {
      if (iid.equals(Ci.nsIWesabeLogger) || iid.equals(Ci.nsISupports)) {
        return this;
      }
      throw Cr.NS_ERROR_NO_INTERFACE;
    };
    WesabeLogger.prototype.getLogFileByFileName = function(name) {
      var file, path;
      path = this.getPathForLogFileName(name);
      file = Cc['@mozilla.org/file/local;1'].createInstance(Ci.nsILocalFile);
      file.initWithPath(path);
      return file;
    };
    WesabeLogger.prototype.getPathForLogFileName = function(name) {
      var ds;
      ds = Cc["@mozilla.org/file/directory_service;1"].getService(Ci.nsIProperties);
      return "" + (ds.get('ProfD', Ci.nsIFile).path) + "/" + name;
    };
    WesabeLogger.prototype.log = function(msg) {
      var date, line, logline, _i, _len, _ref, _results;
      try {
        date = getDateStr();
        _ref = msg.split(/\r?\n/);
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          line = _ref[_i];
          logline = "" + date + ": " + line + "\n";
          _results.push(this.fout.write(logline, logline.length));
        }
        return _results;
      } catch (ex) {
        return dump("WesabeLogger error: log: " + ex.message + "\n");
      }
    };
    WesabeLogger.prototype.debug = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.log.apply(this, args);
    };
    WesabeLogger.prototype.shutdown = {
      observe: function(subject, topic, data) {
        var msg;
        try {
          if (topic === "quit-application") {
            msg = getDateStr() + ": WesabeLogger: shutdown: closing " + WES_WUFF_LOG_TXT + "\n";
            wesLogFoutStream.write(msg, msg.length);
            return wesLogFoutStream.close();
          }
        } catch (ex) {
          return dump("WesabeLogger error: shutdown: " + ex.message + "\n");
        }
      }
    };
    return WesabeLogger;
  })();
  WesabeLoggerFactory = {
    singleton: null,
    createInstance: function(outer, iid) {
      var observerService;
      if (outer !== null) {
        throw Cr.NS_ERROR_NO_AGGREGATION;
      }
      if (this.singleton === null) {
        this.singleton = new WesabeLogger();
        try {
          observerService = Cc["@mozilla.org/observer-service;1"].getService(Ci.nsIObserverService);
          observerService.addObserver(this.singleton.shutdown, "quit-application", false);
        } catch (ex) {
          dump("WesabeLoggerFactory: error on adding QAG observer: " + ex.message + "\n");
        }
      }
      return this.singleton.QueryInterface(iid);
    }
  };
  WesabeLoggerModule = {
    registerSelf: function(compMgr, fileSpec, location, type) {
      compMgr = compMgr.QueryInterface(Ci.nsIComponentRegistrar);
      return compMgr.registerFactoryLocation(WESABE_LOGGER_CID, "Wesabe Logger", WESABE_LOGGER_CONTRACTID, fileSpec, location, type);
    },
    unregisterSelf: function(compMgr, fileSpec, location) {},
    getClassObject: function(compMgr, cid, iid) {
      if (cid.equals(WESABE_LOGGER_CID)) {
        return WesabeLoggerFactory;
      }
      if (!iid.equals(Ci.nsIFactory)) {
        throw Cr.NS_ERROR_NOT_IMPLEMENTED;
      }
      throw Cr.NS_ERROR_NO_INTERFACE;
    },
    canUnload: function(compMgr) {
      return true;
    }
  };
  this.NSGetModule = function(compMgr, fileSpec) {
    return WesabeLoggerModule;
  };
}).call(this);
