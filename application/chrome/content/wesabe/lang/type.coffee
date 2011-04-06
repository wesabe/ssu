wesabe.require('lang.extend')

wesabe.provide 'lang.type',
  isString: (object) ->
    typeof(object) == 'string'

  isNull: (object) ->
    object == null

  isUndefined: (object) ->
    typeof(object) == 'undefined'

  isFunction: (object) ->
    typeof(object) == 'function'

  isBoolean: (object) ->
    (object == true) || (object == false)

  isFalse: (object) ->
    object == false

  isTrue: (object) ->
    object == true

  isNumber: (object) ->
    typeof(object) == 'number'

  isArray: (object) ->
    object &&
    @isNumber(object.length) &&
    @isFunction(object.splice)

  isObject: (object) ->
    typeof(object) == 'object'

  isDate: (object) ->
    object?.constructor == Date || @isFunction(object.getMonth)

  isTainted: (object) ->
    object?.isTainted?()

  is: (object, type) ->
    object?.constructor == type

wesabe.lang.extend(wesabe, wesabe.lang.type)
