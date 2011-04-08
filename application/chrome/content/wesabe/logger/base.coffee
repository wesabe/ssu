wesabe.provide('logger.base')
wesabe.require('lang.*')
wesabe.require('util.*')

sharedLogger = null

wesabe.logger.levels =
  radioactive: 0
  debug:       1
  info:        2
  warn:        3
  error:       4
  fatal:       5

wesabe.logger.levelNameForCode = (level) ->
  return level if typeof level == 'string'

  for own key, value of @levels
    return key if value == level

wesabe.logger.levelCodeForName = (name) ->
  return name if typeof name == 'number'
  @levels[name]

class wesabe.logger.base
  prefix: ""

  #
  # Base logging function.
  #
  log: (objects, level=wesabe.logger.levels.info) ->
    return if wesabe.logger.level > level
    @_log(wesabe.lang.array.from(objects), level)

  #
  # Use when +str+ may contain sensitive data, such as a password.
  #
  radioactive: ->
    @log(arguments, wesabe.logger.levels.radioactive)

  #
  #Use when logging information that may be useful when debugging.
  #
  debug: ->
    @log(arguments, wesabe.logger.levels.debug)

  #
  # Something that might be interesting happened.
  #
  info: ->
    @log(arguments, wesabe.logger.levels.info)

  #
  # Something might be wrong, but execution will continue normally.
  #
  warn: ->
    @log(arguments, wesabe.logger.levels.warn)

  #
  # Something went wrong enough to terminate the active task, but the app
  # is still going.
  #
  error: ->
    @log(arguments, wesabe.logger.levels.error)

  #
  # Something went *really* wrong and the application needs to terminate.
  #
  fatal: ->
    @log(arguments, wesabe.logger.levels.fatal)

  #
  # Formats the message for display in a log message.
  # @method format
  # @param level {wesabe.logger.levels} The log level of this message.
  # @param args {Array} The contents of the message.
  # @return {String} A formatted log message.
  #
  #   wesabe.logger.format(wesabe.logger.levels.debug, "Hey there");
  #   // => "DEBUG -- Hey there"
  #
  format: (args, level) ->
    strings = for object in wesabe.lang.array.from(args)
                if typeof object == "string"
                  object.replace(/\r/g, '')
                else
                  wesabe.util.inspectForLog(object)

    return "#{wesabe.logger.levelNameForCode(level).toUpperCase()} -- #{@prefix}#{strings.join('')}"

  clone: ->
    clone = new this.constructor()
    clone.prefix = @prefix
    return clone

#
# Allow setting the logger.
#
wesabe.logger.setLogger = (logger) ->
  if typeof logger == "string"
    try
      wesabe.require("logger." + logger)
      logger = new wesabe.logger[logger]()
    catch ex
      dump("setLogger: error: #{ex}")
      return false
  else if typeof logger == "function"
    logger = new logger()

  if typeof logger.log != "function"
    dump("cannot use #{logger} as a logger since it doesn't respond to log\n")
    return false

  try
    dump("Switching logger to #{wesabe.util.inspectForLog(logger)}\n")
    sharedLogger = logger
    dump("Switched logger to #{wesabe.util.inspectForLog(logger)}\n")
    wesabe.info("Now logging with ", logger)
  catch ex
    dump("setLogger: error: #{ex}\n")

  return true


wesabe.logger.colorizeLogging = true

#
# Returns the logger level (as a number).
#
wesabe.logger.__defineGetter__ 'level', ->
  wesabe.logger.levels[wesabe.logger.levelName]

#
# Returns the logger level name.
#
wesabe.logger.__defineGetter__ 'levelName', ->
  wesabe.util.prefs.get('wesabe.logger.level', 'debug')

#
# Allow setting the log level by either name or number.
#
wesabe.logger.__defineSetter__ 'level', (level) ->
  level = @levelNameForCode(level)

  if typeof level != 'string'
    wesabe.warn('logger=: called with ', level, ', which is not a string')
  else
    wesabe.util.prefs.set('wesabe.logger.level', level)


#
# Create a wrapper for the logger that has a certain prefix.
# @method log4
# @param prefix {String} The string to prefix all log messages with.
# @return A logger that always uses +prefix+.
#
wesabe.log4 = (prefix) ->
  logger = sharedLogger.clone()
  logger.prefix ||= ""
  logger.prefix += ": " if logger.prefix.length
  logger.prefix += prefix
  return logger


# Convenience methods on the base wesabe object.
for own method of wesabe.logger.levels
  do (method) ->
    wesabe[method] = ->
      sharedLogger[method].apply(sharedLogger, arguments)
