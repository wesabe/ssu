(function() {
  var Cc, Ci, Cr, FileTyper, MARKER, TYPE, WCS_CID, WesabeSniffer, WesabeSnifferFactory, WesabeSnifferModule;
  var __hasProp = Object.prototype.hasOwnProperty;
  WCS_CID = Components.ID("{707ffd4c-2d95-4d04-af12-38c8137b387d}");
  Cc = Components.classes;
  Ci = Components.interfaces;
  Cr = Components.results;
  WesabeSniffer = (function() {
    function WesabeSniffer() {}
    WesabeSniffer.prototype.QueryInterface = function(iid) {
      if (iid.equals(Ci.nsISupports) || iid.equals(Ci.nsIContentSniffer)) {
        return this;
      }
      throw Cr.NS_ERROR_NO_INTERFACE;
    };
    WesabeSniffer.prototype.dataToString = function(data) {
      var charCode, chars, shortCircuit, _i, _len;
      chars = "";
      shortCircuit = Math.min(data.length, 499);
      data = data.slice(0, shortCircuit);
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        charCode = data[_i];
        if (charCode !== 0) {
          chars += String.fromCharCode(charCode);
        }
      }
      return chars.replace(/^\s+|\s+$/, '');
    };
    WesabeSniffer.prototype.getMIMETypeFromContent = function(request, data, length) {
      var cd, cdHeader, checkable, collecting, compression, con, ext, filename, http, intercept, stringData;
      collecting = true;
      if (collecting) {
        checkable = false;
        try {
          http = request.QueryInterface(Ci.nsIHttpChannel);
          compression = http.getResponseHeader("Content-Encoding");
        } catch (ex) {
          checkable = true;
        }
        ext = "";
        try {
          http = request.QueryInterface(Ci.nsIHttpChannel);
          cdHeader = http.getResponseHeader("content-disposition");
          if (cdHeader.length > 0) {
            cd = cdHeader.toLowerCase().split('filename=');
            if (cd.length > 1 && cd[1].length > 0) {
              filename = cd[1];
              ext = this.sniffExt(filename);
            }
          }
        } catch (ex) {

        }
        if (ext.length > 0 || checkable) {
          intercept = true;
          stringData = this.dataToString(data);
          con = new FileTyper(stringData);
          if (con.isSupportedType() && ext.toUpperCase() !== con.getType()) {
            ext = con.getType();
          }
          if (ext.length > 0) {
            try {
              http = request.QueryInterface(Ci.nsIHttpChannel);
              try {
                http.setResponseHeader("X-SSU-Content-Disposition", http.getResponseHeader("Content-Disposition"), false);
              } catch (ex) {
                dump("WesabeSniffer.getMTFC: can't preserve Content-Disposition header: " + ex.message + "\n");
              }
              http.setResponseHeader("Content-Disposition", "", false);
            } catch (ex) {
              dump("WesabeSniffer.getMTFC: can't unset content-disposition: " + ex.message + "\n");
            }
            try {
              http = request.QueryInterface(Ci.nsIHttpChannel);
              try {
                http.setResponseHeader("X-SSU-Content-Type", http.getResponseHeader("Content-Type"), false);
              } catch (ex) {
                dump("WesabeSniffer.getMTFC: can't preserve Content-Type header: " + ex.message + "\n");
              }
            } catch (ex) {

            }
            return "application/x-ssu-intercept";
          }
        }
      }
    };
    WesabeSniffer.prototype.sniffExt = function(filename) {
      var ext, _ref, _ref2;
      ext = (_ref = filename.match(/\.(\w+)/)) != null ? (_ref2 = _ref[1]) != null ? _ref2.toLowerCase() : void 0 : void 0;
      if (ext === 'ofx' || ext === 'qif' || ext === 'ofc' || ext === 'qfx' || ext === 'pdf') {
        return ext;
      } else {
        return '';
      }
    };
    return WesabeSniffer;
  })();
  WesabeSnifferFactory = {
    createInstance: function(outer, iid) {
      if (outer !== null) {
        throw Cr.NS_ERROR_NO_AGGREGATION;
      }
      return new WesabeSniffer();
    }
  };
  WesabeSnifferModule = {
    firstTime: true,
    registerSelf: function(compMgr, fileSpec, location, type) {
      compMgr = compMgr.QueryInterface(Ci.nsIComponentRegistrar);
      return compMgr.registerFactoryLocation(WCS_CID, "Wesabe Sniffer", "@wesabe.com/contentsniffer;1", fileSpec, location, type);
    },
    unregisterSelf: function(compMgr, fileSpec, location) {},
    getClassObject: function(compMgr, cid, iid) {
      if (!iid.equals(Ci.nsIFactory)) {
        throw Cr.NS_ERROR_NOT_IMPLEMENTED;
      }
      if (cid.equals(WCS_CID)) {
        return WesabeSnifferFactory;
      }
      throw Cr.NS_ERROR_NO_INTERFACE;
    },
    canUnload: function(compMgr) {
      return true;
    }
  };
  this.NSGetModule = function(compMgr, fileSpec) {
    return WesabeSnifferModule;
  };
  TYPE = {
    UNKNOWN: "UNKNOWN",
    OFX1: "OFX/1",
    OFX2: "OFX/2",
    OFC: "OFC",
    QIF: "QIF",
    PDF: "PDF",
    HTML: "HTML",
    MSMONEY: "MSMONEY-DB"
  };
  MARKER = {
    OFX1: new RegExp('OFXHEADER:', "i"),
    OFX2: new RegExp('<?OFX OFXHEADER="200"', "i"),
    OFC: new RegExp('<OFC>', "i"),
    QIF: /(^\^(EUR)*\s*$)|(^!Type:)/im,
    PDF: /^%PDF-/,
    HTML: new RegExp('<HTML', "i"),
    MSMONEY: new RegExp("MSMONEY-DB")
  };
  FileTyper = (function() {
    function FileTyper(contents) {
      this.contents = contents;
      this.filetype = this._guessType();
    }
    FileTyper.prototype._guessType = function() {
      var marker, pattern;
      for (marker in MARKER) {
        if (!__hasProp.call(MARKER, marker)) continue;
        pattern = MARKER[marker];
        if (pattern.test(this.contents)) {
          return TYPE[marker];
        }
      }
      return TYPE.UNKNOWN;
    };
    FileTyper.prototype.getType = function() {
      return this.filetype;
    };
    FileTyper.prototype.toString = function() {
      return this.filetype;
    };
    FileTyper.prototype.isUnknown = function() {
      return this.filetype === TYPE.UNKNOWN;
    };
    FileTyper.prototype.isSupportedType = function() {
      var _ref;
      return (_ref = this.filetype) === TYPE.OFX1 || _ref === TYPE.OFX2 || _ref === TYPE.OFC || _ref === TYPE.QIF || _ref === TYPE.PDF;
    };
    return FileTyper;
  })();
}).call(this);
