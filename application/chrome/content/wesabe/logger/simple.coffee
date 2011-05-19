wesabe.provide('logger.simple')
wesabe.require('logger.base')

#
# Simple Logger prints to STDOUT.
#
class wesabe.logger.simple extends wesabe.logger.base
  _log: (args, level) ->
    dump(@format(args, level) + "\n")
