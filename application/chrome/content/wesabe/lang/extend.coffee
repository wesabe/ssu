extend = (target, source, options={}) ->
  options.override ?= true
  options.merge ?= false

  for own key of source
    if key of target and options.merge and typeof target[key] is 'object' and typeof source[key] is 'object'
      extend target[key], source[key], options

    else if key not of target or options.override
      getter = source.__lookupGetter__(key)
      setter = source.__lookupSetter__(key)

      if getter or setter
        target.__defineGetter__(key, getter) if getter
        target.__defineSetter__(key, setter) if setter
      else
        target[key] = source[key]

  return target

module.exports = extend
