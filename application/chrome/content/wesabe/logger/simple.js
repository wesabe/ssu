wesabe.provide('logger.simple');
wesabe.require('logger.base');

/**
 * Simple Logger prints to STDOUT.
 */
wesabe.logger.simple = {
  _log: function(level, args) {
    if (wesabe.logger.level <= level) {
      var str = wesabe.logger.simple.format(level, args) + "\n";
      dump(str);
    }
  }
};
