type =
  isString: (object) ->
    typeof object is 'string'

  isNull: (object) ->
    object is null

  isUndefined: (object) ->
    typeof object is 'undefined'

  isFunction: (object) ->
    typeof object is 'function' and not (type.isRegExp object)

  isRegExp: (re) ->
    s = "#{re}"
    re instanceof RegExp or # easy case
    # duck-type for context-switching evalcx case
    re and
    re.constructor?.name is 'RegExp' and
    re.compile and
    re.test and
    re.exec and
    /^\/.*\/[gim]{0,3}$/.test(s)

  isBoolean: (object) ->
    object is true or object is false

  isFalse: (object) ->
    object is false

  isTrue: (object) ->
    object is true

  isNumber: (object) ->
    typeof object is 'number'

  isArray: (object) ->
    object and
    typeof object is 'object' and
    (type.isNumber object.length) and
    (type.isFunction object.splice)

  isObject: (object) ->
    typeof object is 'object'

  isDate: (object) ->
    (object?.constructor is Date) or type.isFunction object.getMonth

  isTainted: (object) ->
    object?.isTainted?()

  is: (object, type) ->
    object instanceof type or
    object?.constructor is type

# make all these available as shortcuts on the wesabe object
wesabe ?= require '../../wesabe'
for own name, fn of type
  wesabe[name] = logger.wrapDeprecated "wesabe.#{name}", "type.#{name}", fn, type

# hand it off to whoever required us
module.exports = type
