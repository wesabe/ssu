#
# Provides the basic methods needed to load packages and any functions
# useful enough to live in the core.
#
# NOTE: Much of the package stuff is drawn from Dojo, which is a project
# that is arguably over-engineered and generally stuffy, but hopefully
# taking a small slice out of it will not spread the seeds of doom.
#

window.onerror = (error) ->
  # dump "oh no! #{error}\n"
  if Logger?.rootLogger
    Logger.rootLogger.error "uncaught exception: ", error
  else
    dump "uncaught exception: #{error}"

wesabe =
  #
  # Creates nested modules as given by the module.
  #
  # ==== Parameters
  # module<String>::
  #   The dot-separated name of the module/class that
  #   will be created somewhere after calling this.
  #
  # ==== Returns
  # Object:: The existing or newly created module specified by the argument.
  #
  # ==== Example
  #    wesabe.provide("math.Vector");
  #    wesabe.math.Vector = function() { ... };
  #
  # @private
  #
  provide: (module, value) ->
    parts = module.split('.')
    base = wesabe

    for part, i in parts
      base = (base[part] ||= (i is parts.length-1) and value or {})

    if value
      value.__module__ =
        name: parts[parts.length-1]
        fullName: module

    return base

  CommonJSRequire: (path) ->
    wesabe.require path.replace(/\//g, '.')

  #
  # Loads a file in an attempt to load the specified module/class.
  #
  # ==== Parameters
  # module<String>:: The dot-separated name of the module/class to load.
  #
  # ==== Returns
  # Object:: The module, if it could be loaded.
  #
  # ==== Raises
  # Error:: If the file couldn't be loaded, an error is thrown.
  #
  # ==== Example
  #   # looks for files in this order:
  #   # wesabe/math/vector.js
  #   # wesabe/math.js
  #   # wesabe/math/__package__.js
  #   wesabe.require("math.vector");
  #
  #   # specifying an asterisk last changes the order:
  #   # wesabe/math/vector/__package__.js
  #   # wesabe/math/vector.js
  #   # wesabe/math.js
  #   # wesabe/math/__package__.js
  #
  require: (module) ->
    # split "A.B" into ["A", "B"]
    module = wesabe._parseModuleUri(module)

    return module.exports if module.exports

    uris = wesabe._getUrisForParts module.parts, module.scheme
    module.exports = {}

    for uri in uris
      if wesabe._loadUri uri, module
        wesabe.walk module.name, (part, mod, level, levels) =>
          if level is levels.length - 1
            module.exports = (mod[part] ||= module.exports)
          else
            mod[part] ||= {}

        module.exports.__module__ =
          name: module.parts[module.parts.length-1]
          fullName: module.name
          uri: uri

        return module.exports

    throw new Error "Failed to load #{module.name}. Are you sure the files are in the right place?"

  _parseModuleUri: (module) ->
    m = module.match(/^(?:([-\w]+):\/\/)?([-\w\.\/]+?(?:\.\*)?)$/)
    if not m
      throw new Error "Parsing module uri '#{module}' failed"

    scheme = m[1] or 'chrome'
    path = m[2]
    parts = path.split /[\.\/]/
    result =
      scheme: scheme
      name: module
      parts: parts

    if parts[parts.length-1] isnt '*'
      result.exports = wesabe.walk(module)

    return result

  baseUrlForScheme: (scheme) ->
    wesabe._baseUris ||= {}

    wesabe._baseUris[scheme] ||= try
      result = document.evaluate '//*[contains(@src, "wesabe.coffee")]', document, null, XPathResult.ANY_TYPE, null, null
      script = result?.iterateNext()

      if !script
        throw "Could not determine the base url for the scripts. make sure this file is named wesabe.coffee."

      script.getAttribute('src').replace(/\.coffee/, '')
    catch e
      dump "baseUrlForScheme: #{e}\n"
      null

  #
  # Transforms an array of module parts to a list of possible Uris.
  # @method _getUrisForParts
  # @param parts {Array} The list of module parts.
  # @param lookForPackages {Boolean} Whether to look for a package file at all.
  # @param preferPackages {Boolean} Whether to look for a package file first.
  # @private
  #
  _getUrisForParts: (parts, scheme, lookForPackages, preferPackages) ->
    s = wesabe.baseUrlForScheme(scheme)
    u = (pp) ->
      base = [s].concat(pp).join('/')
      return [base + '.js', base + '.coffee']

    if parts.length is 0
      return []

    if parts[parts.length-1] is '*'
      parts.pop()
      lookForPackages = preferPackages = true

    uris = []
    # A/B/C/__package__.{js,coffee}
    if lookForPackages
      uris = uris.concat(u(parts.concat(['__package__'])))

    # A/B/C.{js,coffee}
    if preferPackages
      uris = uris.concat(u(parts))
    else
      uris = u(parts).concat(uris)

    # start over with A/B
    uris.concat(wesabe._getUrisForParts(parts[0...parts.length-1], scheme, true, false))

  walk: (module, callback) ->
    base = wesabe

    parts = module.split('.')
    for part, i in parts
      callback?(part, base, i, parts)
      base &&= base[part]

    return base

  #
  # All the Uris loaded by _loadUri.
  # @private
  #
  _loadedUris: []

  #
  # File offset in number of lines.
  #
  _locOffset: null

  #
  # The line number of the eval statement in this file.
  #
  _evalOffset: null

  #
  # Returns the file and line number that the evaled code at a given line is from.
  #
  fileAndLineFromEvalLine: (lineno) ->
    for uri in wesabe._loadedUris
      if lineno > uri.offset and lineno <= uri.offset+uri.loc
        return file: uri.file, lineno: lineno-uri.offset

  #
  # Loads (and evals) the JS file at +uri+. Returns true on success.
  # @method _loadUri
  # @param uri {String} The uri to the JS file to load and eval.
  # @private
  #
  _loadUri: (uri, module) ->
    if wesabe._loadedUris[uri]
      return true

    contents = wesabe._getEvalText(uri)
    return false unless contents

    # figure out LOC offset and EVAL offset
    if wesabe._locOffset is null
      lines = wesabe._getEvalText(wesabe.getMyURI()).split(/\n/)
      for line, i in lines
        # can't actually use the same value we're looking for, or this'll be found first
        if /_{2}EVAL_{2}/.test(lines[i])
          wesabe._evalOffset = i
          break

      wesabe._locOffset = lines.length
      wesabe._loadedUris[wesabe.getMyURI()] =
        offset: 0
        loc: lines.length
        file: wesabe.getMyURI()

      wesabe._loadedUris.push wesabe._loadedUris[wesabe.getMyURI()]

    loc = contents.split(/\n/).length

    wesabe._loadedUris[uri] =
      offset: wesabe._locOffset
      loc: loc
      file: uri

    wesabe._loadedUris.push wesabe._loadedUris[uri]

    __FILE__ = uri
    padding = new Array(wesabe._locOffset-wesabe._evalOffset+1).join('\n')
    wesabe._locOffset += loc

    try
      _exportsOriginal = module.exports
      exports = module.exports
      require = wesabe.CommonJSRequire
      logger  = Logger?.loggerForFile __FILE__
      Cc      = Components.classes
      Ci      = Components.interfaces

      # run the file code inside a closure with exports as the context
      (->
        eval("#{padding}#{contents}\r\n//@ sourceUri=#{uri}") # __EVAL__

        # if the file changed exports, re-save it
        if _exportsOriginal isnt exports
          module.exports = exports

      ).call(exports)

    catch e
      dump "!! Error while evaluating code from #{uri}: #{e}\n"
      dump "\n\n#{contents}\n\n"

    return true

  getMyURI: ->
    return wesabe._myURI if wesabe._myURI

    for script in document.getElementsByTagName('script')
      if script.getAttribute('src').match(/wesabe.coffee/)
        return wesabe._myURI = script.getAttribute('src')

  #
  # Gets the text at the given uri.
  # @method _getText
  # @param uri {String} The uri to the file to get the text of.
  # @private
  #
  _getText: (uri) ->
    xhr = new XMLHttpRequest()

    xhr.open 'GET', uri, false
    try
      xhr.send null
    catch e
      # uh oh, 404?
      return null

    if xhr.status in [0, 200]
      xhr.responseText
    else
      null

  _evalTextByURI: {}

  _getEvalText: (uri) ->
    return @_evalTextByURI[uri] if @_evalTextByURI[uri]

    text = @_getText uri

    return unless text

    if /\.coffee$/.test uri
      try
        text = CoffeeScript.compile(text)
      catch e
        dump "!! Unable to compile CoffeeScript file #{uri}: #{e}\n"
        return null

    @_evalTextByURI[uri] = text

@wesabe = wesabe
@require = wesabe.CommonJSRequire

Logger = @require 'Logger'
inspect = @require 'util/inspect'

# colorize the logging
Logger.rootLogger.printer = (object) ->
  if typeof object is 'string'
    # top-level strings don't get quotes or color since they're probably just log messages
    object
  else
    inspect object, undefined, undefined, on
