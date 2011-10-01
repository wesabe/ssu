Cc = Components.classes
Ci = Components.interfaces

Components.utils.import "resource://gre/modules/XPCOMUtils.jsm"

gObserver = Cc['@mozilla.org/observer-service;1'].getService(Ci.nsIObserverService)
gIOService = Cc["@mozilla.org/network/io-service;1"].getService(Ci.nsIIOService)

class CertsService
  observe: (aSubject, aTopic, aData) ->
    switch aTopic
      when "app-startup"
        gObserver.addObserver this, "xpcom-shutdown", false
        gObserver.addObserver this, "final-ui-startup", false
      when "xpcom-shutdown"
        gObserver.removeObserver this, "final-ui-startup"
        gObserver.removeObserver this, "xpcom-shutdown"
      when "final-ui-startup"
        @init()

  init: ->
    # add all certificates you want to install here (or read this from your prefs.js ...)
    for cert in ["verisign-ofx.crt", "wesabe-cacert.crt"]
      @addCertificate cert, 'C,c,c'

  addCertificate: (CertName, CertTrust) ->
    logger = @getLoggerComponent()

    try
      logger.log "INFO -- CertsService#addCertificate: adding cert file #{CertName} with trust level #{CertTrust}"
      certDB = Cc["@mozilla.org/security/x509certdb;1"].getService(Ci.nsIX509CertDB2)
      scriptableStream=Cc["@mozilla.org/scriptableinputstream;1"].getService(Ci.nsIScriptableInputStream)
      channel = gIOService.newChannel "chrome://desktopuploader/content/certs/#{CertName}", null, null
      input = channel.open()
      scriptableStream.init(input)
      certfile = scriptableStream.read(input.available())
      scriptableStream.close()
      input.close()

      beginCert = "-----BEGIN CERTIFICATE-----"
      endCert = "-----END CERTIFICATE-----"

      certfile = certfile.replace(/[\r\n]/g, "")
      begin = certfile.indexOf beginCert
      end = certfile.indexOf endCert
      cert = certfile.substring begin + beginCert.length, end
      certDB.addCertFromBase64 cert, CertTrust, ""
    catch e
      logger.log "ERROR -- CertsService#addCertificate: exception while adding cert: #{e.message}"

  getLoggerComponent: ->
    try
      Cc["@wesabe.com/logger;1"].getService(Ci.nsIWesabeLogger)
    catch e
      return log: (message) -> dump "#{message}\n"

  classDescription: "Certificate Service"
  contractID: "@mozilla.org/certs-service;2"
  classID: Components.ID("{e9d2d37c-bf25-4e37-82a1-16b8fa089939}")
  QueryInterface: XPCOMUtils.generateQI([Ci.nsIObserver])
  _xpcom_categories: [{
    category: "app-startup"
    service: true
  }]

@NSGetModule = (compMgr, fileSpec) ->
  XPCOMUtils.generateModule [CertsService]
