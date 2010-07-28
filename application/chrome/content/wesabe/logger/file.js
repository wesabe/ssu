wesabe.provide('logger.file');
wesabe.require('logger.simple');

/**
 * File Logger prints to a file.
 */
wesabe.logger.file = {
  init: function() {
    wesabe.logger.file.registerLoggerComponent();
  },

  _log: function(level, args) {
    try {
      if (wesabe.logger.level <= level) {
        var str = wesabe.logger.file.format(level, args);
        wesabe.logger.file.getLoggerComponent().log(str);
      }
    } catch(ex) {
      dump("error while logging: " + ex + "\n");
      wesabe.logger.simple._log(level, args);
    }
  },

  getLoggerComponent: function() {
    return Components.classes["@wesabe.com/logger;1"]
      .getService(Components.interfaces.nsIWesabeLogger);
  },

  registerLoggerComponent: function() {
    wesabe.debug('registerLoggerComponent');
    try {
      // Wesabe Logger registration - if not already registered.
      var catMgr = Components.classes["@mozilla.org/categorymanager;1"]
                      .getService(Components.interfaces.nsICategoryManager);
      var shouldRegister = true;
      var cats = catMgr.enumerateCategories();
      while (cats.hasMoreElements() && shouldRegister) {
        var cat = cats.getNext();
        var catName = cat.QueryInterface(Components.interfaces.nsISupportsCString).data;
        if (catName === "loggers") {
            var catEntries = catMgr.enumerateCategory(cat);
            while (catEntries.hasMoreElements()) {
            var catEntry = catEntries.getNext();
            var catEntryName =
              catEntry.QueryInterface(Components.interfaces.nsISupportsCString).data;
            if (catEntryName === "Wesabe Logger")
              shouldRegister = false;
            }
        }
      }
      if (shouldRegister) {
        wesabe.debug('registering Wesabe Logger with category manager');
        catMgr.addCategoryEntry("loggers", "Wesabe Logger", "@wesabe.com/logger;1", false, true);
      }
    } catch(ex) {
      wesabe.error('registerLoggerComponent: error: ' + ex);
    }
  }
};
