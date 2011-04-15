pref("toolkit.defaultChromeURI", "chrome://desktopuploader/content/main.xul");
pref("toolkit.defaultChromeFeatures", "chrome,resizable=yes,dialog=no,centerscreen=yes");
// suppress external-load warning for standard browser schemes
pref("network.protocol-handler.warn-external.http", false);
pref("network.protocol-handler.warn-external.https", false);


/* debugging prefs */
pref("browser.dom.window.dump.enabled", true);
pref("javascript.options.showInConsole", true);
pref("javascript.options.strict", true);
pref("nglayout.debug.disable_xul_cache", true);
pref("nglayout.debug.disable_xul_fastload", true);
