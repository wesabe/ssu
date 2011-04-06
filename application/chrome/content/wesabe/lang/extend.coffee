wesabe.provide('lang')

wesabe.lang.extend = (target, source, override=true) ->
  for own key of source
    if override || (typeof(target[key]) == 'undefined')
      getter = source.__lookupGetter__(key)
      setter = source.__lookupSetter__(key)

      if getter || setter
        target.__defineGetter__(key, getter) if getter
        target.__defineSetter__(key, setter) if setter
      else
        target[key] = source[key]

  return target
