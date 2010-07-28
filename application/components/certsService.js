const Cc = Components.classes;
const Ci = Components.interfaces;

Components.utils.import("resource://gre/modules/XPCOMUtils.jsm");

const gObserver = Cc['@mozilla.org/observer-service;1'].getService(Ci.nsIObserverService);
const gIOService = Cc["@mozilla.org/network/io-service;1"].getService(Ci.nsIIOService);

function CertsService() {}

CertsService.prototype = {
    observe: function(aSubject, aTopic, aData) {
        switch(aTopic) {
            case "app-startup":
                gObserver.addObserver(this,"xpcom-shutdown",false);
                gObserver.addObserver(this,"final-ui-startup",false);
                break;
            case "xpcom-shutdown":
                gObserver.removeObserver(this,"final-ui-startup");
                gObserver.removeObserver(this,"xpcom-shutdown");
                break;
            case "final-ui-startup":
                this.init();
                break;
        }
    },

    init: function() {
      // add all certificates you want to install here (or read this from your prefs.js ...)
      var certs = ["verisign-ofx.crt", "wesabe-cacert.crt"];
      for (var i=0; i<certs.length; i++) {
        this.addCertificate(certs[i], 'C,c,c');
      }
    },

    addCertificate: function(CertName, CertTrust) {
      var logger = this.getLoggerComponent();

      try {
        logger.log("INFO -- CertsService#addCertificate: adding cert file " + CertName + " with trust level " + CertTrust);
        var certDB = Cc["@mozilla.org/security/x509certdb;1"].getService(Ci.nsIX509CertDB2);
        var scriptableStream=Cc["@mozilla.org/scriptableinputstream;1"].getService(Ci.nsIScriptableInputStream);
        var channel = gIOService.newChannel("chrome://desktopuploader/content/certs/" + CertName, null, null);
        var input=channel.open();
        scriptableStream.init(input);
        var certfile=scriptableStream.read(input.available());
        scriptableStream.close();
        input.close();

        var beginCert = "-----BEGIN CERTIFICATE-----";
        var endCert = "-----END CERTIFICATE-----";

        certfile = certfile.replace(/[\r\n]/g, "");
        var begin = certfile.indexOf(beginCert);
        var end = certfile.indexOf(endCert);
        var cert = certfile.substring(begin + beginCert.length, end);
        certDB.addCertFromBase64(cert, CertTrust, "");
      } catch (e) {
        logger.log("ERROR -- CertsService#addCertificate: exception while adding cert: " + e.message);
      }
    },

    getLoggerComponent: function() {
      try {
        return Components.classes["@wesabe.com/logger;1"]
          .getService(Components.interfaces.nsIWesabeLogger);
      } catch (e) {
        return {log: function(message){ dump(message + "\n"); }};
      }
    },

    classDescription: "Certificate Service",
    contractID: "@mozilla.org/certs-service;2",
    classID: Components.ID("{e9d2d37c-bf25-4e37-82a1-16b8fa089939}"),
    QueryInterface: XPCOMUtils.generateQI([Ci.nsIObserver]),
    _xpcom_categories: [{
        category: "app-startup",
        service: true
    }]
}

function NSGetModule(compMgr, fileSpec) {
    return XPCOMUtils.generateModule([CertsService]);
}
