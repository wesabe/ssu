#
# Provides the basic methods needed to load packages and any functions
# useful enough to live in the core.
#
# NOTE: Much of the package stuff is drawn from Dojo, which is a project
# that is arguably over-engineered and generally stuffy, but hopefully
# taking a small slice out of it will not spread the seeds of doom.
#

if window? and not GLOBAL?
  # we're in a DOM-ish environment rather than a commonjs-ish environment
  window.GLOBAL = window

GLOBAL.onerror = (error) ->
  # dump "oh no! #{error}\n"
  try
    Logger.rootLogger.error "uncaught exception: ", error
  catch cantLogException
    dump "uncaught exception: #{error}"

# lazy-load privacy.untaint
untaint = (args...) ->
  {untaint} = require 'util/privacy'
  untaint args...

# hold the already-required required modules
required = {}

wesabe =
  caller: ->
    caller = (require 'util/error').stackTrace new Error()
    caller.frames.shift() # remove this call
    return caller

  getLineForStackFrame: (frame) ->
    (bootstrap.getContent frame.filename).split('\n')[frame.lineNumber]

  correctStackFrameInfo: (frame) ->
    evalFile = window.bootstrap.uri
    if frame.filename[frame.filename.length-evalFile.length..] is evalFile
      if info = bootstrap.infoForEvaledLineNumber frame.lineNumber
        frame.filename = info.filename
        frame.lineNumber = info.lineNumber
        frame.line = info.line
        frame.name = info.name if info.name


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
    return required[module].exports if required[module]

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

        required[module.name] = module
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
    content = bootstrap.getContent uri
    return false unless content

    try
      exports = _exportsOriginal = module.exports

      bootstrap.load uri,
        __filename: uri
        __dirname:  uri.replace /\/[^\/]+$/, ''
        module:     module
        exports:    exports
        require:    wesabe.CommonJSRequire
        logger:     Logger?.loggerForFile uri
        Cc:         Components.classes
        Ci:         Components.interfaces

      # if the file changed exports, re-save it
      if _exportsOriginal isnt exports
        module.exports = exports

    catch e
      dump "!! Error while evaluating code from #{uri}: #{e}\n"
      dump "\n\n#{content}\n\n"

    return true

walk = (module, callback) ->
  base = wesabe

  parts = module.split('.')
  for part, i in parts
    callback?(part, base, i, parts)
    base &&= base[part]

  return base

GLOBAL.wesabe = wesabe

# if we ain't in a commonjs environment then set up our own
require ?= wesabe.CommonJSRequire
GLOBAL.require = require

# NOTE: We load Logger before everything else, otherwise nobody loaded before
# Logger will have their `logger' object in scope.
Logger  = require 'Logger'
GLOBAL.logger ?= Logger.rootLogger

inspect = require 'util/inspect'
prefs   = require 'util/prefs'
type    = require 'lang/type'
{trim}  = require 'lang/string'


# colorize the logging if appropriate
Logger.rootLogger.printer = (object) ->
  if typeof object is 'string'
    # top-level strings don't get quotes or color since they're probably just log messages
    object

  else if object instanceof Error
    trace = (require 'util/error').stackTrace(object)
    result = "#{object.message}\n\n"

    if lineText = trace.frames[0]?.line
      lineText = trim lineText
      lineText = lineText[0...38]+'...'+lineText[lineText.length-35...lineText.length] if lineText.length > 76

      result += "On:\n    #{lineText}\n"

    result += "Backtrace:\n"

    for {name, filename, lineNumber} in trace.frames
      if name.length < 40
        result += ' ' for i in [0...(40 - name.length)]
      else
        name = "#{name[0...37]}..."

      result += "#{name} at #{filename}:#{lineNumber}\n"

    return result

  else
    inspect object, undefined, undefined, color: prefs.get('wesabe.logger.color') ? on

# write logs to a file rather than stdout
Logger.rootLogger.appender = Logger.getFileAppender()
