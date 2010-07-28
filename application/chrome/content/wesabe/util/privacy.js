wesabe.provide('util.privacy');

/**
 * Clears all private information.
 * @method clearAllPrivateData
 */
wesabe.util.privacy.clearAllPrivateData = function() {
  wesabe.tryCatch('wesabe.util.privacy.clearAllPrivateData', function() {
    wesabe.util.privacy.clearCookies();
    wesabe.util.privacy.clearHistory();
    wesabe.util.privacy.clearCache();
    wesabe.util.privacy.clearAuthenticatedSessions();
  });
};

/**
 * Clears all cookies.
 * @method clearCookies
 */
wesabe.util.privacy.clearCookies = function() {
  wesabe.tryCatch('wesabe.util.privacy.clearCookies', function() {
    var cookieManager = Components.classes["@mozilla.org/cookiemanager;1"]
                          .getService(Components.interfaces.nsICookieManager);
    cookieManager.removeAll();
  });
};

wesabe.util.privacy.clearHistory = function() {
  wesabe.tryCatch('wesabe.util.privacy.clearHistory', function() {
    var globalHistory = Components.classes["@mozilla.org/browser/global-history;2"]
                          .getService(Components.interfaces.nsIBrowserHistory);
    globalHistory.removeAllPages();
  });
};

/**
 * Clears the cache -- NOT IMPLEMENTED.
 * @method clearCache
 */
wesabe.util.privacy.clearCache = function() {
  wesabe.warn('wesabe.util.privacy.clearCache is not implemented');
};

/**
 * Clears all authenticated sessions -- NOT IMPLEMENTED.
 * @method clearAuthenticatedSessions
 */
wesabe.util.privacy.clearAuthenticatedSessions = function() {
  wesabe.warn('wesabe.util.privacy.clearAuthenticatedSessions is not implemented');
};

/**
 * Clears anything that looks like an account number from the string.
 *
 *   wesabe.util.privacy.sanitize("123-456-7890"); // "xxx-xxx-xxxx"
 */
wesabe.util.privacy.sanitize = function(string) {
  wesabe.util.privacy.sanitize._sanitizers.forEach(function(ns) {
    var name = ns[0], sanitizer = ns[1];
    string = sanitizer(string);
  });
  return string;
};

wesabe.util.privacy.sanitize.registerSanitizer = function(name, sanitizer) {
  if (sanitizer instanceof RegExp) {
    var pattern = sanitizer;
    sanitizer = function(string){ return string.replace(pattern, '<<masked '+name+'>>') };
  }
  wesabe.util.privacy.sanitize._addSanitizer(name, sanitizer);
};

wesabe.util.privacy.sanitize._addSanitizer = function(name, sanitizer) {
  var s = wesabe.util.privacy.sanitize;
  if (!s._sanitizers) s._sanitizers = [];
  s._sanitizers.push([name, sanitizer]);
};

wesabe.util.privacy.sanitize.registerSanitizer('Account Number', function(string) {
  return string.toString().replace(/([-\d]{4,})/g, function(num) {
    return num.replace(/\d/g, 'x');
  });
});


/**
 * Convenience method for tainting objects.
 */
wesabe.util.privacy.taint = function(o) {
  if (wesabe.isTainted(o)) {
    return o;
  } else {
    var wrappers = wesabe.util.privacy.taint._wrappers;
    for (var i = 0; i < wrappers.length; i++) {
      if (wrappers[i].canHandle(o))
        return wrappers[i].wrap(o);
    }
    wesabe.warn("not tainting value: ", o);
    return o;
  }
};

wesabe.taint = wesabe.util.privacy.taint;

/**
 * Convenience method for untainting objects.
 */
wesabe.util.privacy.untaint = function(o) {
  if (wesabe.isTainted(o)) {
    return o.untaint();
  } else if (wesabe.isArray(o)) {
    return o.map(function(el){ return wesabe.untaint(el) });
  } else {
    return o;
  }
};

wesabe.untaint = wesabe.util.privacy.untaint;



wesabe.util.privacy.taint.registerWrapper = function(options) {
  var detector = options.detector,
      getters = options.getters,
      sanitizer = options.sanitizer,
      generator = options.generator;

  var wrapper = function(object){ this.__wrapped__ = object };

  // handle method calls
  wrapper.prototype.__noSuchMethod__ = function(method, args) {
    var untaintedResult = this.__wrapped__[method].apply(this.__wrapped__, args);
    return wesabe.util.privacy.taint(untaintedResult);
  };

  // handle getters
  if (!getters)
    getters = [];

  getters.forEach(function(getter) {
    wrapper.prototype.__defineGetter__(getter, function() {
      var untaintedResult = this.__wrapped__[getter];
      return wesabe.util.privacy.taint(untaintedResult);
    });
  });

  // handle custom methods
  wrapper.prototype.isTainted = function() { return true };

  wrapper.prototype.untaint = function() { return this.__wrapped__ };

  wrapper.prototype.sanitize = function() {
    return sanitizer?
      sanitizer(this.__wrapped__) :
      wesabe.util.privacy.sanitize(this.__wrapped__);
  };

  wrapper.prototype.toString = function() { return this.sanitize() };

  wrapper.canHandle = detector;
  wrapper.wrap = generator || function(o){ return new wrapper(o) };

  return wesabe.util.privacy.taint._addWrapper(wrapper);
};

wesabe.util.privacy.taint._addWrapper = function(wrapper) {
  var t = wesabe.util.privacy.taint;
  if (!t._wrappers) t._wrappers = [];
  t._wrappers.push(wrapper);
};

// wrapper for String
wesabe.util.privacy.taint.registerWrapper({
  detector: function(o){ return wesabe.isString(o) },
  getters: ['length']
});

// wrapper for Array
wesabe.util.privacy.taint.registerWrapper({
  detector: function(o){ return o && wesabe.isFunction(o.map) },
  generator: function(o) {
    var tarray = o.map(function(el){ return wesabe.util.privacy.taint(el) })
    tarray.isTainted = function(){ return true };
    tarray.untaint   = function() {
      return this.map(function(el){ return wesabe.util.privacy.untaint(el) });
    };
    return tarray;
  }
});

// wrapper for Element
wesabe.util.privacy.taint.registerWrapper({
  detector: function(o){ return o instanceof Element },
  getters: [
    "attributes", "childNodes", "className", "clientHeight", "clientLeft",
    "clientTop", "clientWidth", "dir", "firstChild", "href", "id", "innerHTML", "lang",
    "lastChild", "localName", "Name", "name", "namespaceURI", "nextSibling",
    "nodeName", "nodeType", "nodeValue", "offsetHeight", "offsetLeft",
    "offsetParent", "offsetTop", "offsetWidth", "ownerDocument", "Name",
    "parentNode", "prefix", "previousSibling", "scrollHeight", "scrollLeft",
    "scrollTop", "scrollWidth", "style", "tabIndex", "tagName", "textContent", "type",
    "value"
  ]
});

// wrapper for text nodes
wesabe.util.privacy.taint.registerWrapper({
  detector: function(o){ return o instanceof Text },
  getters: [
    "ATTRIBUTE_NODE", "CDATA_SECTION_NODE", "COMMENT_NODE", "DOCUMENT_FRAGMENT_NODE",
    "DOCUMENT_NODE", "DOCUMENT_POSITION_CONTAINED_BY", "DOCUMENT_POSITION_CONTAINS",
    "DOCUMENT_POSITION_DISCONNECTED", "DOCUMENT_POSITION_FOLLOWING",
    "DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC", "DOCUMENT_POSITION_PRECEDING",
    "DOCUMENT_TYPE_NODE", "ELEMENT_NODE", "ENTITY_NODE", "ENTITY_REFERENCE_NODE", "NOTATION_NODE",
    "PROCESSING_INSTRUCTION_NODE", "TEXT_NODE", "attributes", "baseURI", "childNodes", "data",
    "firstChild", "lastChild", "length", "localName", "namespaceURI", "nextSibling", "nodeName",
    "nodeType", "nodeValue", "ownerDocument", "parentNode", "prefix", "previousSibling",
    "textContent"
  ]
});

// wrapper for null/undefined
wesabe.util.privacy.taint.registerWrapper({
  detector: function(o){ return wesabe.isNull(o) || wesabe.isUndefined(o) },
  generator: function(o){ return o }
});

// wrapper for Number
wesabe.util.privacy.taint.registerWrapper({
  detector: function(o){ return wesabe.isNumber(o) },
  generator: function(o){ return o }
});
