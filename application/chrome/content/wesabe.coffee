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
  try
    Logger.rootLogger.error "uncaught exception: ", error
  catch cantLogException
    dump "uncaught exception: #{error}"


loadedContent = []
evalContentCache = {}
contentInfoCache = {}
evalFile = 'coffee-script.js'
evalLine = null
evaled = ''


getEvalLine = ->
  return evalLine if evalLine

  evalFileContent = getEvalContent evalFile
  evaled += evalFileContent

  for line, i in evalFileContent.split '\n'
    if line.match /\beval\(/
      evalLine = i
      break

  if evalLine is null
    throw new Error "unable to determine eval line for file #{evalFile}"

  return evalLine

getContent = (uri) ->
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

getEvalContent = (uri) ->
  return evalContentCache[uri] if evalContentCache[uri]

  content = getContent uri
  return unless content

  if /\.coffee$/.test uri
    try
      content = CoffeeScript.compile content
    catch e
      dump "!! Unable to compile CoffeeScript file: #{uri}: #{e}\n"
      return null

  evalContentCache[uri] = content

getContentInfo = (uri) ->
  return contentInfoCache[uri] if contentInfoCache[uri]

  content = getEvalContent uri
  return unless content

  offset = getEvalLine()
  lines  = content.split('\n').length
  evalLine += lines

  contentInfoCache[uri] = {content, offset, lines}
  dump "#{uri}, offset=#{offset}, lines=#{lines}\n"
  contentInfoCache[uri]

getOriginalLineInfo = (evaledOffset) ->
  evaledLines = evaled.split('\n')
  for uri, {content, offset, lines} of contentInfoCache
    if offset <= evaledOffset < offset + lines
      originalLineNumber = evaledOffset - offset + 1
      originalLineContent = content.split('\n')[originalLineNumber-1]
      ll = (evaledLines[evaledOffset+i] for i in [-2..2])
      Logger.rootLogger.debug "\noriginalLineContent=#{originalLineContent}\nevaled[#{evaledOffset}]:\n#{ll.join('\n')}\n"
      return {line: originalLineContent, lineNumber: originalLineNumber, uri}


wesabe =
  caller: ->
    (require 'util/error').stackTrace new Error()

  getLineForStackFrame: (frame) ->
    (getEvalContent frame.filename).split('\n')[frame.lineNumber]

  correctStackFrameInfo: (frame) ->
    evalFile = window.bootstrap.uri
    Logger.rootLogger.debug "correcting #{frame.filename}:#{frame.lineNumber} | #{frame.filename[frame.filename.length-evalFile.length..]}"
    if frame.filename[frame.filename.length-evalFile.length..] is evalFile
      if info = bootstrap.infoForEvaledLineNumber frame.lineNumber
        Logger.rootLogger.debug "--> #{info.toSource()}"
        frame.filename = info.filename
        frame.lineNumber = info.lineNumber
        frame.line = info.line


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
  provide: (module, value={}) ->
    parts = module.split('.')

    walk module, (part, mod, level, levels) =>
      if level is levels.length - 1
        mod[part] = value
      else
        mod[part] ||= {}

    value.__module__ =
      name: parts[parts.length-1]
      fullName: module

    return value

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
        walk module.name, (part, mod, level, levels) =>
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

  #
  # Loads (and evals) the JS file at +uri+. Returns true on success.
  # @method _loadUri
  # @param uri {String} The uri to the JS file to load and eval.
  # @private
  #
  _loadUri: (uri, module) ->
    if loadedContent[uri]
      return true

    info = getContentInfo uri
    return false unless info

    loadedContent[uri] = true
    loadedContent.push loadedContent[uri]

    #padding = new Array(info.offset+1).join('\n')

    try
      exports = _exportsOriginal = module.exports

      bootstrap.load uri,
        __FILE__: uri
        module:   module
        exports:  exports
        require:  wesabe.CommonJSRequire
        logger:   Logger?.loggerForFile uri
        Cc:       Components.classes
        Ci:       Components.interfaces

      # if the file changed exports, re-save it
      if _exportsOriginal isnt exports
        module.exports = exports

    catch e
      dump "!! Error while evaluating code from #{uri}: #{e}\n"
      dump "\n\n#{contents}\n\n"

    return true

  getMyURI: ->
    return wesabe._myURI if wesabe._myURI

    for script in document.getElementsByTagName('script')
      if script.getAttribute('src').match(/wesabe.coffee/)
        return wesabe._myURI = script.getAttribute('src')

walk = (module, callback) ->
  base = wesabe

  parts = module.split('.')
  for part, i in parts
    callback?(part, base, i, parts)
    base &&= base[part]

  return base

@wesabe = wesabe
@require = wesabe.CommonJSRequire

Logger  = @require 'Logger'
inspect = @require 'util/inspect'
prefs   = @require 'util/prefs'

# colorize the logging if appropriate
Logger.rootLogger.printer = (object) ->
  if typeof object is 'string'
    # top-level strings don't get quotes or color since they're probably just log messages
    object
  else
    inspect object, undefined, undefined, prefs.get('wesabe.logger.color') ? on

# write logs to a file rather than stdout
Logger.rootLogger.appender = Logger.getFileAppender()

setTimeout ->
  Logger.rootLogger.debug new Error(), (require 'util/error').stackTrace(new Error())
, 0
