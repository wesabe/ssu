prefs = require 'util/prefs'

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
    @_level or @_parent?._level or levelCodeForName prefs.get('wesabe.logger.level')

  @::__defineSetter__ 'level', (level) ->
    @_level = if level? then levelNameForCode level else level

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


  constructor: (@name='', @_parent=Logger.rootLogger) ->
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
  # Formats the message for display in a log message.
  #
  format: (objects, level) ->
    strings = for object in objects
                try
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

  Logger.rootLogger.debug 'Registering file logger'

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
      Logger.rootLogger.debug 'registering Wesabe Logger with category manager'
      catMgr.addCategoryEntry "loggers", "Wesabe Logger", "@wesabe.com/logger;1", false, true

    fileLogger = Cc["@wesabe.com/logger;1"].getService(Ci.nsIWesabeLogger)

    fileAppender = (text) ->
      fileLogger.log text

  catch ex
    Logger.rootLogger.error '!! error registering file logger: ', ex


module.exports = Logger
