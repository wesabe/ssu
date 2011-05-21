# run with:
# $ rake spec
# OR
# $ npm install jasmine-node
# $ jasmine-node --coffee spec

exports.wesabe =
  log: [],

  provide: (module, value) ->
    @walk module, (part, mod, level, levels) ->
      mod[part] ||= if value? and (level is levels.length - 1)
        value
      else
        {}

  require: (module) ->
    require "../application/chrome/content/wesabe/#{module.replace('.', '/')}"
    @walk module

  taint: (object) ->
    object

  untaint: (object) ->
    object

  radioactive: (args...) ->
    @log.push 'radioactive', args

  debug: (args...) ->
    @log.push 'debug', args

  info: (args...) ->
    @log.push 'info', args

  warn: (args...) ->
    @log.push 'warn', args

  error: (args...) ->
    @log.push 'error', args

  fatal: (args...) ->
    @log.push 'fatal', args

  walk: (module, callback) ->
    base = wesabe
    parts = module.split('.')

    for part, i in parts
      callback part, base, i, parts if callback?
      base = base[part]

    return base
