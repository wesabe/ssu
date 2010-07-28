wesabe.provide('util.prefs');

/**
 * Allows getting, setting, serializing, and deserializing preferences.
 */
wesabe.util.prefs = {
  /**
   * Loads preferences from a Mozilla prefs.js format preference file.
   * Example:
   *
   *   $ cat prefs.js
   *   # Mozilla Preference File
   *   pref('network.proxy.http', 'proxy.oak.wesabe.com');
   *   pref('network.proxy.http_port', 8080);
   *   pref('network.proxy.type', 1);
   *
   *   wesabe.util.prefs.load('prefs.js');
   *   wesabe.util.prefs.get('network.proxy.type'); // => 1
   *
   * WARNING: At this point this function is NOT SAFE and will eval the
   * contents of the file in a non-safe way. Please know what you're doing.
   */
  load: function(path) {
    wesabe.tryCatch('prefs.load('+path+')', function(log) {
      var file = wesabe.io.file.open(path);
      var data = wesabe.io.file.read(file);

      if (/^#/.test(data)) {
        // data includes unparseable first line, remove it
        data = data.replace(/^#[^\n]*/, '');
      }

      wesabe.lang.func.callWithScope(data, this, {
        pref: wesabe.util.prefs.set
      });
    });
  },

  get root() {
    var service = Components.classes['@mozilla.org/preferences-service;1']
      .getService(Components.interfaces.nsIPrefService);
    return service.getBranch('');
  },

  /**
   * Get a preference by its full name. Example:
   *
   *   wesabe.util.prefs.get('browser.dom.window.dump.enabled'); // => false
   */
  get: function(key, defaultValue) {
    var root = wesabe.util.prefs.root;

    // maybe it's a String
    try { return root.getCharPref(key); }
    catch(e) {}

    // maybe it's a Boolean
    try { return root.getBoolPref(key); }
    catch(e) {}

    // maybe it's a Number
    try { return root.getIntPref(key); }
    catch(e) {}

    // not found
    return defaultValue;
  },

  /**
   * Set a preference by its full name. Example:
   *
   *   wesabe.util.prefs.set('browser.dom.window.dump.enabled', true);
   */
  set: function(key, value) {
    var root = wesabe.util.prefs.root;
    if (wesabe.isBoolean(value)) {
      root.setBoolPref(key, value);
    } else if (wesabe.isString(value)) {
      root.setCharPref(key, value);
    } else if (wesabe.isNumber(value)) {
      root.setIntPref(key, value);
    } else {
      throw new Error('Could not set preference for key='+key+
        ', unknown type for value='+wesabe.util.inspect(value));
    }
  },

  /**
   * Clears a preference by its full name. Example:
   *
   *   wesabe.util.prefs.clear('general.useragent.override');
   */
  clear: function(key) {
    try { wesabe.util.prefs.root.clearUserPref(key); }
    catch (e) {
      // pref probably didn't exist, but make sure it's gone
      if (!wesabe.isUndefined(wesabe.util.prefs.get(key)))
        wesabe.error("Could not clear pref with key=", key, " due to an error: ", e);
    }
  },
};
