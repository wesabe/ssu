exports.wesabe =

  ## MODULE GENERATION

  provide: (module, value) ->
    walk module, (part, mod, level, levels) ->
      mod[part] ||= if value? and (level is levels.length - 1)
        value
      else
        {}

  require: (module) ->
    parts = module.split('.')
    if parts[parts.length-1] == '*'
      parts[parts.length-1] = '__package__'
      module = parts[0..-2].join('.')

    loaded = require "../application/chrome/content/wesabe/#{parts.join('/')}"

    walk module, (part, mod, level, levels) ->
      mod[part] ||= if level is levels.length - 1
        loaded
      else
        {}

## INTERNAL

walk = (module, callback) ->
  base = wesabe
  parts = module.split('.')

  for part, i in parts
    callback part, base, i, parts if callback?
    base &&= base[part]

  return base
