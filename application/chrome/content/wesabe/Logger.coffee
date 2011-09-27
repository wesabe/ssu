#prefs = require 'util/prefs'
#
# NOTE: instead of using `require' for all these we lazy-load them,
# otherwise `logger' will not be available for them since, duh, we're
# the logger and haven't loaded yet.
#
isTainted = (args...) ->
  {isTainted} = require 'lang/type'
  isTainted args...
untaint = (args...) ->
  {untaint} = require 'util/privacy'
  untaint args...
getPref = (args...) ->
  getPref = (require 'util/prefs').get
  getPref args...

loggersByName = {}

LEVELS =
  radioactive: 0
  debug:       1
  info:        2
  warn:        3
  error:       4
  fatal:       5

levelNameForCode = (level) ->
  return level if typeof level is 'string'

  for own key, value of LEVELS
    return key if value is level

  return null

levelCodeForName = (name) ->
  return name if typeof name is 'number'
  LEVELS[name]

class Logger
  @LEVELS: LEVELS

  #
  # Level is how much attention you should pay to something.
  # The higher the level, the more attention you should pay.
  #
  @::__defineGetter__ 'level', ->
    @_level ? @_parent?._level ? levelCodeForName getPref('wesabe.logger.level')

  @::__defineSetter__ 'level', (level) ->
    @_level = (levelCodeForName level) ? level

  @::__defineGetter__ 'levelName', ->
    levelNameForCode @level

  #
  # Appenders append text to things, like stdout or a file.
  #
  @::__defineGetter__ 'appender', ->
    @_appender or @_parent?._appender or (text) -> dump "#{text}\n"

  @::__defineSetter__ 'appender', (appender) ->
    @_appender = appender

  #
  # Printers take objects and turn them into pretty text.
  #
  @::__defineGetter__ 'printer', ->
    @_printer or @_parent?._printer or (object) -> "#{object}"

  @::__defineSetter__ 'printer', (printer) ->
    @_printer = printer


  #
  # Determines whether to log anything at all, regardless of level.
  #
  @::__defineGetter__ 'enabled', ->
    @_enabled ? @_parent?._enabled ? on

  @::__defineSetter__ 'enabled', (enabled) ->
    @_enabled = enabled


  constructor: (@name='', @_parent=rootLogger) ->
    @_enabled = null

  @__defineGetter__ 'rootLogger', ->
    rootLogger

  @loggerForFile: (file) ->
    file = file.replace /\.\w+$/, ''
    loggersByName[file] ||= new Logger(file)

  #
  # Base logging function.
  #
  log: (objects, level=LEVELS.info) ->
    return if @level > level or @enabled is false
    objects = [objects] unless 'length' of objects

    @appender @format(objects, level)
    null

  #
  # Use when logging sensitive data, such as a password.
  #
  radioactive: (args...) ->
    @log args, LEVELS.radioactive

  #
  # Use when logging information that may be useful when debugging.
  #
  debug: (args...) ->
    @log args, LEVELS.debug

  #
  # Something that might be interesting happened.
  #
  info: (args...) ->
    @log args, LEVELS.info

  #
  # Something might be wrong, but execution will continue normally.
  #
  warn: (args...) ->
    @log args, LEVELS.warn

  #
  # Something went wrong enough to terminate the active task, but the app
  # is still going.
  #
  error: (args...) ->
    @log args, LEVELS.error

  #
  # Something went *really* wrong and the application needs to terminate.
  #
  fatal: (args...) ->
    @log args, LEVELS.fatal

  #
  # Logs info about a deprecated method call.
  #
  deprecated: (name, alternate=null) ->
    @warn new Error "DEPRECATION WARNING: A deprecated method was called: #{name}#{alternate and ", use #{alternate} instead" or ""}."

  wrapDeprecated: (name, alternate, fn, context) ->
    (args...) =>
      @deprecated name, alternate
      fn.call context, args...

  #
  # Formats the message for display in a log message.
  #
  format: (objects, level) ->
    strings = for object in objects
                try
                  if level is LEVELS.radioactive
                    object = untaint object if isTainted object

                  (@printer object).replace /\r/g, ''
                catch ex
                  dump "ERROR: while printing object (#{object}) for log: #{ex}\n"
                  "#{object}"

    level = levelNameForCode(level).toUpperCase()
    lines = strings.join('').split(/\r?\n/)

    return ("#{level} -- #{@name and "#{@name}: "}#{line}" for line in lines).join('\n')

rootLogger = new Logger()
fileAppender = null

setTimeout ->
  require 'util/error'
, 0

Logger.getFileAppender = ->
  return fileAppender if fileAppender

  rootLogger.debug 'Registering file logger'

  try
    # Wesabe Logger registration - if not already registered.
    catMgr = Cc["@mozilla.org/categorymanager;1"].getService(Ci.nsICategoryManager)
    shouldRegister = true
    cats = catMgr.enumerateCategories()
    while cats.hasMoreElements() && shouldRegister
      cat = cats.getNext()
      catName = cat.QueryInterface(Ci.nsISupportsCString).data
      if catName is "loggers"
        catEntries = catMgr.enumerateCategory(cat)
        while catEntries.hasMoreElements()
          catEntry = catEntries.getNext()
          catEntryName = catEntry.QueryInterface(Ci.nsISupportsCString).data
          shouldRegister = false if catEntryName is "Wesabe Logger"

    if shouldRegister
      rootLogger.debug 'registering Wesabe Logger with category manager'
      catMgr.addCategoryEntry "loggers", "Wesabe Logger", "@wesabe.com/logger;1", false, true

    fileLogger = Cc["@wesabe.com/logger;1"].getService(Ci.nsIWesabeLogger)

    fileAppender = (text) ->
      fileLogger.log text

  catch ex
    rootLogger.error '!! error registering file logger: ', ex


module.exports = Logger


# DEPRECATIONS
#
# Anyone used to be able to access the "root" logger by simply
# calling logging methods on the wesabe object:
#
#   wesabe.debug "I'm a lumberjack and I'm okay."
#
# That has since been replaced with a distinct logger per file
# with the "root" logger residing at Logger.rootLogger.
#
# This will still allow calls to wesabe.debug etc. but with
# a nice fat deprecation warning.
for own level of LEVELS
  do (level) ->
    wesabe[level] = (args...) ->
      rootLogger.deprecated "wesabe.#{level}(...)", "logger.#{level}(...)"
      rootLogger[level](args...)
