/***
 * Wesabe Firefox Uploader
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

const WCS_CONTRACTID    = "net-content-sniffers";
const WCS_CID           = Components.ID("{707ffd4c-2d95-4d04-af12-38c8137b387d}");
const WES_IS_COLLECT  = "wes.is-collecting-data";

function WesabeSniffer () {
}


WesabeSniffer.prototype.QueryInterface = function (iid) {
  if (iid.equals(Components.interfaces.nsISupports) ||
      iid.equals(Components.interfaces.nsIContentSniffer))
      return this;
  throw Components.results.NS_ERROR_NO_INTERFACE;
}


WesabeSniffer.prototype.dataToString = function(data) {
  var chars = "";
  shortCurcuit = (data.length < 499) ? data.length : 499;
  for (var i=0; i < shortCurcuit; i++)
    if (data[i] != 0) chars += String.fromCharCode(data[i]);
  return chars.replace(/^\s+|\s+$/, '');
}

WesabeSniffer.prototype.getMIMETypeFromContent = function(request, data, length) {
  var collecting = true;  
  if (collecting) {
      // Checkable - data is uncompressed and available for inspection/verification of file type
    var checkable = false;
      try {
      /*
      var chan = request.QueryInterface(Components.interfaces.nsIChannel);
      dump("WesabeSniffer.getMTFC: mime-type: " + chan.contentType);
      */
      var http = request.QueryInterface(Components.interfaces.nsIHttpChannel);
      var compression = http.getResponseHeader("Content-Encoding");
      // dump("WesabeSniffer.getMTFC: encoding-type: " + compression);
      // TODO: 12.4.2007 (tmason@wesabe.com) - use nsIStreamConverterService 
      // (@mozilla.org/streamConverters;1) for a conversion from gzip to uncompressed.
    }
    catch (ex) {
      checkable = true; 
    }

    var ext = "";
      try {
      var http = request.QueryInterface(Components.interfaces.nsIHttpChannel);
      var cdHeader = http.getResponseHeader("content-disposition");
      // dump("WesabeSniffer.getMTFC: content-disposition: " + cdHeader);
      if (cdHeader.length > 0) {
        var cd = cdHeader.toLowerCase().split('filename=');
        if (cd.length > 1 && cd[1].length > 0) {
          var filename = "";
          for (var i=1;i<cd.length;i++) filename += cd[i];
          // dump("WesabeSniffer.getMTFC: filename: " + filename);
          ext = this.sniffExt(filename);
          // dump("WesabeSniffer.getMTFC: sniffed extension revealed '" + ext + "'");
        }
      }
    }
    catch (ex) { 
      /* do nothing - merely means the header does not exist */ 
    }
  
    if (ext.length > 0 || checkable) {
      // dump("WesabeSniffer.getMTFC: --- Content sniffing --- ");
      var intercept = true;
      var stringData = this.dataToString(data);
      // dump("WesabeSniffer: getMTFC: checking data: \n" + stringData.substring(0, 25) + "\n");
      
      var con = this.sniffContent(stringData);
      // dump("WesabeSniffer: getMTFC: sniffed content revealed: '" + con + "' versus '" + ext + "'");
      if (con.length > 0 && ext !== con) ext = con;

      if (ext.length > 0) {
        try {
          var http = request.QueryInterface(Components.interfaces.nsIHttpChannel);
          http.setResponseHeader("content-disposition", "", false);
        }
        catch (ex) {
          dump("WesabeSniffer.getMTFC: can't unset content-disposition: " + ex.message);
        }
        // dump("WesabeSniffer.getMTFC: mime type of 'application/x-wes-" + ext + "'");
        if (ext && ext === 'qif')
          return "application/x-wes-nofx"; 
        else 
          return "application/x-wes-ofx"; 
      }
      }
  }
    
}

WesabeSniffer.prototype.sniffExt = function(filename) {
  if (filename.indexOf('.ofx') >= 0) return "ofx";
  if (filename.indexOf('.qif') >= 0) return "qif";
  if (filename.indexOf('.ofc') >= 0) return "ofc";
  if (filename.indexOf('.qfx') >= 0) return "qfx";
  return "";  
}

WesabeSniffer.prototype.sniffContent = function(content) {
  typer = new FileTyper(content);
  filetype = typer.get_type();
  if (typer.is_supported_type()) 
    return typer.needs_more_info() ? "qif" : "ofx"; 
  else 
    return "";
}

var WesabeSnifferFactory = new Object();

WesabeSnifferFactory.createInstance = function (outer, iid) {
  if (outer != null)
    throw Components.results.NS_ERROR_NO_AGGREGATION;

  return new WesabeSniffer();
}


var WesabeSnifferModule = new Object();

WesabeSnifferModule.firstTime = true;

WesabeSnifferModule.registerSelf = function (compMgr, fileSpec, location, type) {
  var compMgr = 
      compMgr.QueryInterface(Components.interfaces.nsIComponentRegistrar);
  compMgr.registerFactoryLocation(WCS_CID, "Wesabe Sniffer", 
                                  "@wesabe.com/contentsniffer;1", 
                                  fileSpec, location, type);
};

WesabeSnifferModule.unregisterSelf = function(compMgr, fileSpec, location) {}

WesabeSnifferModule.getClassObject = function (compMgr, cid, iid) {
  if (!iid.equals(Components.interfaces.nsIFactory))
    throw Components.results.NS_ERROR_NOT_IMPLEMENTED;

  if (cid.equals(WCS_CID))
    return WesabeSnifferFactory;

  throw Components.results.NS_ERROR_NO_INTERFACE;
    
}

WesabeSnifferModule.canUnload = function(compMgr) {
  return true;
}

function NSGetModule(compMgr, fileSpec) {
  return WesabeSnifferModule;
}


// FileTyper - guess at the type of data file based on magic-number-like markers

FileTyper.TYPE = {
  UNKNOWN : "UNKNOWN",
  OFX1    : "OFX/1",
  OFX2    : "OFX/2",
  OFC     : "OFC",
  QIF     : "QIF",
  PDF     : "PDF",
  HTML    : "HTML",
  MSMONEY : "MSMONEY-DB",
}

// These regexes are run in (random, I think) order over the contents,
// so be sure that none of the overlap.

FileTyper.MARKER = {
  OFX1    : new RegExp('OFXHEADER:', "i"),
  OFX2    : new RegExp('<?OFX OFXHEADER="200"', "i"),
  OFC     : new RegExp('<OFC>', "i"),
  QIF     : /(^\^(EUR)*\s*$)|(^!Type:)/im,
  PDF     : /^%PDF-/,
  HTML    : new RegExp('<HTML', "i"),
  MSMONEY : new RegExp("MSMONEY-DB"),
}

function FileTyper(contents) {
  this.contents = contents;
  this.filetype = this._guess_type();
}

FileTyper.prototype._guess_type = function() {
  // Try each format-specific marker in turn.
  for (var marker in FileTyper.MARKER) {
    if (FileTyper.MARKER[marker].test(this.contents)) {
      return FileTyper.TYPE[marker];
    }
  }
  return FileTyper.TYPE.UNKNOWN;
}

FileTyper.prototype.get_type = function() {
  return this.filetype;
}

FileTyper.prototype.is_supported_type = function() {
  return (this.filetype === FileTyper.TYPE.OFX1 || this.filetype === FileTyper.TYPE.OFX2 ||
          this.filetype === FileTyper.TYPE.OFC  || this.filetype === FileTyper.TYPE.QIF);
}

FileTyper.prototype.needs_more_info = function() {
  return (this.filetype === FileTyper.TYPE.QIF);
}
