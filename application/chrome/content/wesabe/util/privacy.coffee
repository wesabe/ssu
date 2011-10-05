type = require 'lang/type'

sanitizers = []
wrappers = []

{tryCatch, tryThrow} = require 'util/try'

privacy =
  #
  # Clears all private information.
  # @method clearAllPrivateData
  #
  clearAllPrivateData: ->
    tryCatch 'privacy.clearAllPrivateData', =>
      @clearCookies()
      @clearHistory()
      @clearCache()
      @clearAuthenticatedSessions()

  #
  # Clears all cookies.
  # @method clearCookies
  #
  clearCookies: ->
    tryCatch 'privacy.clearCookies', =>
      cookieManager = Cc["@mozilla.org/cookiemanager;1"].getService(Ci.nsICookieManager)
      cookieManager.removeAll()

  clearHistory: ->
    tryCatch 'privacy.clearHistory', =>
      globalHistory = Cc["@mozilla.org/browser/global-history;2"].getService(Ci.nsIBrowserHistory)
      globalHistory.removeAllPages()

  #
  # Clears the cache -- NOT IMPLEMENTED.
  # @method clearCache
  #
  clearCache: ->
    logger.warn 'privacy.clearCache is not implemented'

  #
  # Clears all authenticated sessions -- NOT IMPLEMENTED.
  # @method clearAuthenticatedSessions
  #
  clearAuthenticatedSessions: ->
    logger.warn 'privacy.clearAuthenticatedSessions is not implemented'

  #
  # Clears anything that looks like an account number from the string.
  #
  #   privacy.sanitize("123-456-7890"); // "xxx-xxx-xxxx"
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
    return o if type.isTainted o

    for wrapper in wrappers
      if wrapper.canHandle(o)
        return wrapper.wrap(o)

    logger.warn "not tainting value: ", o
    return o

  #
  # Convenience method for untainting objects.
  #
  untaint: (o) ->
    if type.isTainted o
      o.untaint()
    else if type.isArray o
      privacy.untaint item for item in o
    else
      o

  registerTaintWrapper: (options) ->
    {detector, getters, sanitizer, generator} = options

    wrapper = (object) ->
      @__wrapped__ = object

    # handle method calls
    wrapper::__noSuchMethod__ = (method, args) ->
      untaintedResult = @__wrapped__[method].apply(@__wrapped__, args)
      privacy.taint(untaintedResult)

    # handle getters
    getters ||= []

    for getter in getters
      wrapper::__defineGetter__ getter, ->
        untaintedResult = @__wrapped__[getter]
        privacy.taint(untaintedResult)

    # handle custom methods
    wrapper::isTainted = -> true
    wrapper::untaint = -> @__wrapped__

    wrapper::sanitize = ->
      if sanitizer
        sanitizer(@__wrapped__)
      else
        privacy.sanitize(@__wrapped__)

    wrapper::toString = -> @sanitize()

    wrapper.canHandle = detector
    wrapper.wrap = generator || (o) -> new wrapper(o)

    wrappers.push(wrapper)


# Standard sanitizers & wrappers

privacy.registerSanitizer 'Account Number', (string) ->
  string.toString().replace /([-\d]{4,})/g, (num) ->
    num.replace(/\d/g, 'x')

# wrapper for String
privacy.registerTaintWrapper
  detector: type.isString
  getters: ['length']

# wrapper for Array
privacy.registerTaintWrapper
  detector: (o) -> o && type.isFunction(o.map)
  generator: (o) ->
    tarray = (privacy.taint(item) for item in o)
    tarray.isTainted = -> true
    tarray.untaint   = ->
      privacy.untaint(item) for item in this

    return tarray

# wrapper for Element
privacy.registerTaintWrapper
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
privacy.registerTaintWrapper
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
privacy.registerTaintWrapper
  detector: (o) -> type.isNull(o) or type.isUndefined(o)
  generator: (o) -> o

# wrapper for Number
privacy.registerTaintWrapper
  detector: type.isNumber
  generator: (o) -> o


wesabe ?= require '../../wesabe'
wesabe.untaint = logger.wrapDeprecated 'wesabe.untaint', 'privacy.untaint', privacy.untaint
wesabe.taint = logger.wrapDeprecated 'wesabe.taint', 'privacy.taint', privacy.taint


module.exports = privacy
