Logger = null

tryCatch = (name, fn) ->
  [success, value] = tryThis name, fn

  return value

tryThrow = (name, fn) ->
  [success, value] = tryThis name, fn

  if success
    return value
  else
    throw value

tryThis = (name, fn) ->
  # lazy-load Logger so as not to get into require loops
  Logger ||= require 'Logger'
  logger = Logger.loggerForFile name

  try
    logger.debug 'BEGIN'
    result = fn logger
    logger.debug 'END'

    return [true, result]
  catch ex
    logger.error 'error:\n', ex
    return [false, ex]


module.exports = {tryCatch, tryThrow}
