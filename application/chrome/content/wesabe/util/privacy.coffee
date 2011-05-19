sanitizers = []
wrappers = []

wesabe.provide 'util.privacy',
  #
  # Clears all private information.
  # @method clearAllPrivateData
  #
  clearAllPrivateData: ->
    wesabe.tryCatch 'wesabe.util.privacy.clearAllPrivateData', =>
      @clearCookies()
      @clearHistory()
      @clearCache()
      @clearAuthenticatedSessions()

  #
  # Clears all cookies.
  # @method clearCookies
  #
  clearCookies: ->
    wesabe.tryCatch 'wesabe.util.privacy.clearCookies', =>
      cookieManager = Components.classes["@mozilla.org/cookiemanager;1"]
                        .getService(Components.interfaces.nsICookieManager)
      cookieManager.removeAll()

  clearHistory: ->
    wesabe.tryCatch 'wesabe.util.privacy.clearHistory', =>
      globalHistory = Components.classes["@mozilla.org/browser/global-history;2"]
                        .getService(Components.interfaces.nsIBrowserHistory)
      globalHistory.removeAllPages()

  #
  # Clears the cache -- NOT IMPLEMENTED.
  # @method clearCache
  #
  clearCache: ->
    wesabe.warn('wesabe.util.privacy.clearCache is not implemented')

  #
  # Clears all authenticated sessions -- NOT IMPLEMENTED.
  # @method clearAuthenticatedSessions
  #
  clearAuthenticatedSessions: ->
    wesabe.warn('wesabe.util.privacy.clearAuthenticatedSessions is not implemented')

  #
  # Clears anything that looks like an account number from the string.
  #
  #   wesabe.util.privacy.sanitize("123-456-7890"); // "xxx-xxx-xxxx"
  #
  sanitize: (string) ->
    for [_, sanitizer] in sanitizers
      string = sanitizer(string)

    return string

  registerSanitizer: (name, sanitizer) ->
    if sanitizer instanceof RegExp
      pattern = sanitizer
      sanitizer = (string) ->
        string.replace(pattern, "<<masked #{name}>>")

    sanitizers.push([name, sanitizer])

  #
  # Convenience method for tainting objects.
  #
  taint: (o) ->
    return o if wesabe.isTainted(o)

    for wrapper in wrappers
      if wrapper.canHandle(o)
        return wrapper.wrap(o)

    wesabe.warn("not tainting value: ", o)
    return o

  #
  # Convenience method for untainting objects.
  #
  untaint: (o) ->
    if wesabe.isTainted(o)
      o.untaint()
    else if wesabe.isArray(o)
      wesabe.untaint(item) for item in o
    else
      o

  registerTaintWrapper: (options) ->
    {detector, getters, sanitizer, generator} = options

    wrapper = (object) ->
      @__wrapped__ = object

    # handle method calls
    wrapper::__noSuchMethod__ = (method, args) ->
      untaintedResult = @__wrapped__[method].apply(@__wrapped__, args)
      wesabe.util.privacy.taint(untaintedResult)

    # handle getters
    getters ||= []

    for getter in getters
      wrapper::__defineGetter__ getter, ->
        untaintedResult = @__wrapped__[getter]
        wesabe.util.privacy.taint(untaintedResult)

    # handle custom methods
    wrapper::isTainted = -> true
    wrapper::untaint = -> @__wrapped__

    wrapper::sanitize = ->
      if sanitizer
        sanitizer(@__wrapped__)
      else
        wesabe.util.privacy.sanitize(@__wrapped__)

    wrapper::toString = -> @sanitize()

    wrapper.canHandle = detector
    wrapper.wrap = generator || (o) -> new wrapper(o)

    wrappers.push(wrapper)


# Standard sanitizers & wrappers

wesabe.util.privacy.registerSanitizer 'Account Number', (string) ->
  string.toString().replace /([-\d]{4,})/g, (num) ->
    num.replace(/\d/g, 'x')

# wrapper for String
wesabe.util.privacy.registerTaintWrapper
  detector: wesabe.isString
  getters: ['length']

# wrapper for Array
wesabe.util.privacy.registerTaintWrapper
  detector: (o) -> o && wesabe.isFunction(o.map)
  generator: (o) ->
    tarray = (wesabe.util.privacy.taint(item) for item in o)
    tarray.isTainted = -> true
    tarray.untaint   = ->
      wesabe.util.privacy.untaint(item) for item in this

    return tarray

# wrapper for Element
wesabe.util.privacy.registerTaintWrapper
  detector: (o) -> o instanceof Element
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

# wrapper for text nodes
wesabe.util.privacy.registerTaintWrapper
  detector: (o) -> o instanceof Text
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

# wrapper for null/undefined
wesabe.util.privacy.registerTaintWrapper
  detector: (o) -> wesabe.isNull(o) || wesabe.isUndefined(o)
  generator: (o) -> o

# wrapper for Number
wesabe.util.privacy.registerTaintWrapper
  detector: wesabe.isNumber
  generator: (o) -> o


wesabe.untaint = wesabe.util.privacy.untaint
wesabe.taint = wesabe.util.privacy.taint
