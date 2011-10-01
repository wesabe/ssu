(function() {
  var Cc, CertsService, Ci, gIOService, gObserver;
  Cc = Components.classes;
  Ci = Components.interfaces;
  Components.utils["import"]("resource://gre/modules/XPCOMUtils.jsm");
  gObserver = Cc['@mozilla.org/observer-service;1'].getService(Ci.nsIObserverService);
  gIOService = Cc["@mozilla.org/network/io-service;1"].getService(Ci.nsIIOService);
  CertsService = (function() {
    function CertsService() {}
    CertsService.prototype.observe = function(aSubject, aTopic, aData) {
      switch (aTopic) {
        case "app-startup":
          gObserver.addObserver(this, "xpcom-shutdown", false);
          return gObserver.addObserver(this, "final-ui-startup", false);
        case "xpcom-shutdown":
          gObserver.removeObserver(this, "final-ui-startup");
          return gObserver.removeObserver(this, "xpcom-shutdown");
        case "final-ui-startup":
          return this.init();
      }
    };
    CertsService.prototype.init = function() {
      var cert, _i, _len, _ref, _results;
      _ref = ["verisign-ofx.crt", "wesabe-cacert.crt"];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        cert = _ref[_i];
        _results.push(this.addCertificate(cert, 'C,c,c'));
      }
      return _results;
    };
    CertsService.prototype.addCertificate = function(CertName, CertTrust) {
      var begin, beginCert, cert, certDB, certfile, channel, end, endCert, input, logger, scriptableStream;
      logger = this.getLoggerComponent();
      try {
        logger.log("INFO -- CertsService#addCertificate: adding cert file " + CertName + " with trust level " + CertTrust);
        certDB = Cc["@mozilla.org/security/x509certdb;1"].getService(Ci.nsIX509CertDB2);
        scriptableStream = Cc["@mozilla.org/scriptableinputstream;1"].getService(Ci.nsIScriptableInputStream);
        channel = gIOService.newChannel("chrome://desktopuploader/content/certs/" + CertName, null, null);
        input = channel.open();
        scriptableStream.init(input);
        certfile = scriptableStream.read(input.available());
        scriptableStream.close();
        input.close();
        beginCert = "-----BEGIN CERTIFICATE-----";
        endCert = "-----END CERTIFICATE-----";
        certfile = certfile.replace(/[\r\n]/g, "");
        begin = certfile.indexOf(beginCert);
        end = certfile.indexOf(endCert);
        cert = certfile.substring(begin + beginCert.length, end);
        return certDB.addCertFromBase64(cert, CertTrust, "");
      } catch (e) {
        return logger.log("ERROR -- CertsService#addCertificate: exception while adding cert: " + e.message);
      }
    };
    CertsService.prototype.getLoggerComponent = function() {
      try {
        return Cc["@wesabe.com/logger;1"].getService(Ci.nsIWesabeLogger);
      } catch (e) {
        return {
          log: function(message) {
            return dump("" + message + "\n");
          }
        };
      }
    };
    CertsService.prototype.classDescription = "Certificate Service";
    CertsService.prototype.contractID = "@mozilla.org/certs-service;2";
    CertsService.prototype.classID = Components.ID("{e9d2d37c-bf25-4e37-82a1-16b8fa089939}");
    CertsService.prototype.QueryInterface = XPCOMUtils.generateQI([Ci.nsIObserver]);
    CertsService.prototype._xpcom_categories = [
      {
        category: "app-startup",
        service: true
      }
    ];
    return CertsService;
  })();
  this.NSGetModule = function(compMgr, fileSpec) {
    return XPCOMUtils.generateModule([CertsService]);
  };
}).call(this);
