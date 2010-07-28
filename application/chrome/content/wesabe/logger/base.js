wesabe.provide('logger.base');
wesabe.require('lang.*');
wesabe.require('util.*');

wesabe.logger.levels = {
  radioactive: 0,
  debug: 1,
  info: 2,
  warn: 3,
  error: 4,
  fatal: 5
};

/**
 * Allow setting the logger.
 */
wesabe.logger.setLogger = function(logger) {
  if (typeof logger == "string") {
    try {
      wesabe.require("logger." + logger);
      logger = wesabe.logger[logger];
    } catch(ex) {
      dump("setLogger: error: " + ex);
      return false;
    }
  }

  if (typeof logger._log != "function") {
    dump("cannot use " + logger + " as a logger since it doesn't respond to _log\n");
    return false;
  }
  try {
    dump("Switching logger to " + wesabe.util.inspectForLog(logger) + "\n");
    wesabe.lang.extend(logger, wesabe.logger.base, false); // add 'debug', 'info', 'warn', etc
    if (typeof logger.init == "function") logger.init();
    wesabe._logger = logger;
    dump("Switched logger to " + wesabe.util.inspectForLog(logger) + "\n");
    wesabe.info("Now logging with ", logger);
  } catch(ex) {
    dump('setLogger: error: ' + ex + '\n');
  }

  return true;
};

/**
 * Formats the message for display in a log message.
 * @method format
 * @param level {wesabe.logger.levels} The log level of this message.
 * @param str {String} The contents of the message.
 * @return {String} A formatted log message.
 *
 *   wesabe.logger.format(wesabe.logger.levels.debug, "Hey there");
 *   // => "DEBUG -- Hey there"
 */
wesabe.logger.format = function(level, str) {
  for (var key in wesabe.logger.levels) {
    if (wesabe.logger.levels[key] == level) {
      level = key.toUpperCase();
      break;
    }
  }

  return level + ' -- ' + str;
};

wesabe.logger.colorizeLogging = true;

/**
 * Returns the logger level (as a number).
 */
wesabe.logger.__defineGetter__('level', function() {
  return wesabe.logger.levels[wesabe.logger.levelName];
});

/**
 * Returns the logger level name.
 */
wesabe.logger.__defineGetter__('levelName', function() {
  return wesabe.util.prefs.get('wesabe.logger.level', 'debug');
});

/**
 * Allow setting the log level by either name or number.
 */
wesabe.logger.__defineSetter__('level', function(level) {
  if (typeof level == 'number') {
    for (var key in wesabe.logger.levels)
      if (wesabe.logger.level[key] == level) level = key;
  }

  if (typeof level != 'string') {
    wesabe.warn('logger=: called with ', level, ', which is not a string');
  } else {
    wesabe.util.prefs.set('wesabe.logger.level', level);
  }
});

/**
 * Proxy log messages to the default logger.
 */
wesabe._log = function(level, str) {
  wesabe._logger._log(level, str);
};

/**
 * Create a wrapper for the logger that has a certain prefix.
 * @method log4
 * @param prefix {String} The string to prefix all log messages with.
 * @return A logger that always uses +prefix+.
 */
wesabe.log4 = function(prefix) {
  var logger = {};
  wesabe.lang.extend(logger, wesabe.logger.base);
  logger._log = function(level, args) {
    args = wesabe.lang.array.from(args);
    args.unshift(prefix + ': ');
    wesabe._log(level, args);
  };
  return logger;
};


/**
 * Module/base for loggers -- just provides some convenience methods.
 */
wesabe.logger.base = {
  /**
   * Use when +str+ may contain sensitive data, such as a password.
   */
  radioactive: function() {
    this._log(wesabe.logger.levels.radioactive, arguments);
  },

  /**
   * Use when logging information that may be useful when debugging.
   */
  debug: function() {
    this._log(wesabe.logger.levels.debug, arguments);
  },

  /**
   * Something that might be interesting happened.
   */
  info: function() {
    this._log(wesabe.logger.levels.info, arguments);
  },

  /**
   * Alias for +info+
   */
  log: function(str, level) {
    this._log(level || wesabe.logger.levels.info, [str]);
  },

  /**
   * Something might be wrong, but execution will continue normally.
   */
  warn: function() {
    this._log(wesabe.logger.levels.warn, arguments);
  },

  /**
   * Something went wrong enough to terminate the active task, but the app
   * is still going.
   */
  error: function() {
    this._log(wesabe.logger.levels.error, arguments);
  },

  /**
   * Something went *really* wrong and the application needs to terminate.
   */
  fatal: function() {
    this._log(wesabe.logger.levels.fatal, arguments);
  },

  format: function(level, args) {
    var objects = wesabe.lang.array.from(args);
    var str = objects.map(function(object) {
      if (typeof object == "string") return object.replace(/\r/g, '');
      else return wesabe.util.inspectForLog(object);
    }).join('');

    return wesabe.logger.format(level, str);
  }
};

wesabe.lang.extend(wesabe, wesabe.logger.base); // allow wesabe.log, etc
