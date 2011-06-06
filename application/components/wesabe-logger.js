/***
 * Wesabe Desktop Uploader
 * Copyright (C) 2007 Wesabe, Inc.
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 */

const WESABE_LOGGER_CONTRACTID    = "@wesabe.com/logger;1";
const WESABE_LOGGER_CID           = Components.ID("{0e2843fd-9579-4ec3-9321-f27e2b3c3fbc}");
const WES_EXT_ID                  = "desktopuploader@wesabe.com";
const WES_WUFF_LOG_TXT            = "wuff_log.txt";

// global for cleanup - there's got to be a better way than a global!
var wesLogFoutStream;

function WesabeLogger () {
  try {
    this.mLog = Components.classes['@mozilla.org/consoleservice;1']
                .getService(Components.interfaces.nsIConsoleService);
                
    this.fout = 
      Components.classes["@mozilla.org/network/file-output-stream;1"]
        .createInstance(Components.interfaces.nsIFileOutputStream);
    wesLogFoutStream = this.fout;
    var file = this.getLogFileByFileName(WES_WUFF_LOG_TXT);
    // file.append(WES_WUFF_LOG_TXT);
    this.fout.init(file, 0x02 | 0x08 | 0x10, 0664, 0);
  }
  catch (ex) {
    dump("WesabeLogger error: " + ex.message + '\n');
  }
}

WesabeLogger.prototype.QueryInterface = function (iid) {
  if (iid.equals(Components.interfaces.nsIWesabeLogger) ||
    iid.equals(Components.interfaces.nsISupports))
      return this;

  throw Components.results.NS_ERROR_NO_INTERFACE;
};

WesabeLogger.prototype.getLogFileByFileName = function(name) {
  var path = this.getPathForLogFileName(name);
  var file = Components.classes['@mozilla.org/file/local;1']
              .createInstance(Components.interfaces.nsILocalFile);
  file.initWithPath(path);
  return file;
};

WesabeLogger.prototype.getPathForLogFileName = function(name) {
  var ds = Components.classes["@mozilla.org/file/directory_service;1"]
              .getService(Components.interfaces.nsIProperties);
  return ds.get('ProfD', Components.interfaces.nsIFile).path + '/' + name;
};

WesabeLogger.prototype.log = function(msg) {
  try {
    var lines = msg.split(/\r?\n/),
        date = WesabeLogger.getDateStr(),
        fout = this.fout;

    lines.forEach(function(line) {
      var logline = date + ": " + line + "\n";
      fout.write(logline, logline.length);
    });
  }
  catch (ex) {
    dump("WesabeLogger error: log: " + ex.message + '\n');
  }
};

WesabeLogger.prototype.debug = WesabeLogger.prototype.log;

WesabeLogger.prototype.shutdown = {
  observe: function(subject, topic, data) {
    try {
      if (topic == "quit-application") {
        var msg = WesabeLogger.getDateStr() + 
          ": WesabeLogger: shutdown: closing " + 
          WES_WUFF_LOG_TXT + "\n";
        wesLogFoutStream.write(msg, msg.length);
        wesLogFoutStream.close();
      }
    } catch (ex) {
      dump("WesabeLogger error: shutdown: " + ex.message + '\n');
    }
  }
};

WesabeLogger.getDateStr = function() {
  var d = new Date();
  var pad = function(n,c) {n=n.toString(); while(n.length<c) n='0'+n; return n}
  
  return d.getFullYear() + "." + pad(d.getMonth()+1,2) + "." + pad(d.getDate(),2) + 
       " " + pad(d.getHours(),2) + ":" + pad(d.getMinutes(),2) + ":" + pad(d.getSeconds(),2) +
       ":" + pad(d.getMilliseconds(),3) + " " + pad(d.getTimezoneOffset()/60,2);
}
var WesabeLoggerFactory = new Object();

WesabeLoggerFactory.singleton = null;    
    
WesabeLoggerFactory.createInstance = function (outer, iid) {
    if (outer != null)
        throw Components.results.NS_ERROR_NO_AGGREGATION;

    if (this.singleton == null) {
      this.singleton = new WesabeLogger();
    try {
      var observerService =
          Components.classes["@mozilla.org/observer-service;1"]
            .getService(Components.interfaces.nsIObserverService);
      observerService.addObserver(this.singleton.shutdown, "quit-application", false);
    }
    catch (ex) {
      dump("WesabeLoggerFactory: error on adding QAG observer: " + ex.message + "\n");
    }
  }
  return this.singleton.QueryInterface(iid);
}

var WesabeLoggerModule = new Object();

WesabeLoggerModule.registerSelf = function (compMgr, fileSpec, location, type) {
    var compMgr = compMgr.QueryInterface(Components.interfaces.nsIComponentRegistrar);
    compMgr.registerFactoryLocation(WESABE_LOGGER_CID, "Wesabe Logger",
                                    WESABE_LOGGER_CONTRACTID, fileSpec, location, type);

};

WesabeLoggerModule.unregisterSelf = function(compMgr, fileSpec, location) {}

WesabeLoggerModule.getClassObject = function(compMgr, cid, iid) {
    if (cid.equals(WESABE_LOGGER_CID))
        return WesabeLoggerFactory;

    if (!iid.equals(Components.interfaces.nsIFactory))
        throw Components.results.NS_ERROR_NOT_IMPLEMENTED;

    throw Components.results.NS_ERROR_NO_INTERFACE;
    
}

WesabeLoggerModule.canUnload = function(compMgr) {
    return true;
}

function NSGetModule(compMgr, fileSpec) {
    return WesabeLoggerModule;
}
