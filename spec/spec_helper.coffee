exports.wesabe =
  provide: (module, value) ->
    @walk module, (part, mod, level, levels) ->
      mod[part] ||= if value? and level is level.length - 1
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

  walk: (module, callback) ->
    base = wesabe
    parts = module.split('.')

    for part, i in parts
      callback part, base, i, parts if callback?
      base = base[part]

    return base
