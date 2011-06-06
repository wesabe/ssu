silentLogging = false

exports.wesabe =

  ## MODULE GENERATION

  provide: (module, value) ->
    @walk module, (part, mod, level, levels) ->
      mod[part] ||= if value? and (level is levels.length - 1)
        value
      else
        {}

  require: (module) ->
    parts = module.split('.')
    if parts[parts.length-1] == '*'
      parts[parts.length-1] = '__package__'
      module = parts[0..-2].join('.')

    require "../application/chrome/content/wesabe/#{parts.join('/')}"
    @walk module

  ## (STUB) TAINT HELPERS

  taint: (object) ->
    object

  untaint: (object) ->
    object

  ## TYPE CHECKING

  isFunction: (object) ->
    typeof object is 'function'

  isString: (object) ->
    typeof object is 'string'

  is: (object, klass) ->
    object?.constructor == klass

  isTainted: -> false

  ## LOGGING

  radioactive: (args...) ->
    @log 'radioactive', args

  debug: (args...) ->
    @log 'debug', args

  info: (args...) ->
    @log 'info', args

  warn: (args...) ->
    @log 'warn', args

  error: (args...) ->
    @log 'error', args

  fatal: (args...) ->
    @log 'fatal', args

  log: (level, args...) ->
    return if silentLogging
    console.log [level.toUpperCase(), ': ', args...].join('')

  setLoggerSilent: (silent) ->
    silentLogging = silent

  tryCatch: (name, callback) ->
    try
      callback wesabe
    catch err
      @error name, ':', err

  tryThrow: (name, callback) ->
    try
      callback wesabe
    catch err
      @error name, ':', err
      throw err

  ## INTERNAL

  walk: (module, callback) ->
    base = wesabe
    parts = module.split('.')

    for part, i in parts
      callback part, base, i, parts if callback?
      base = base[part]

    return base
