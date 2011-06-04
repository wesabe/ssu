wesabe.require('lang.extend')

wesabe.provide 'lang.type',
  isString: (object) ->
    typeof object is 'string'

  isNull: (object) ->
    object == null

  isUndefined: (object) ->
    typeof object is 'undefined'

  isFunction: (object) ->
    typeof object is 'function' and not @isRegExp(object)

  isRegExp: (re) ->
    s = "#{re}"
    re instanceof RegExp or # easy case
    # duck-type for context-switching evalcx case
    re and
    re.constructor.name is 'RegExp' and
    re.compile and
    re.test and
    re.exec and
    s.match(/^\/.*\/[gim]{0,3}$/)

  isBoolean: (object) ->
    object is true or object is false

  isFalse: (object) ->
    object is false

  isTrue: (object) ->
    object is true

  isNumber: (object) ->
    typeof object is 'number'

  isArray: (object) ->
    object &&
    @isNumber(object.length) &&
    @isFunction(object.splice)

  isObject: (object) ->
    typeof object is 'object'

  isDate: (object) ->
    object?.constructor == Date || @isFunction(object.getMonth)

  isTainted: (object) ->
    object?.isTainted?()

  is: (object, type) ->
    object?.constructor == type

wesabe.lang.extend(wesabe, wesabe.lang.type)
