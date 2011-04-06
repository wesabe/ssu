wesabe.require('lang.array')
wesabe.provide('lang.json')

wesabe.lang.json =
  parse: (string) ->
    eval("(#{string})")

  render: (object) ->
    @_render(object, [])

  _render: (object, refs) ->
    return @_render('$$ circular reference $$', refs) if wesabe.lang.array.include(refs, object)

    if wesabe.isString(object)
      @_renderString(object)
    else if wesabe.isNull(object)
      @_renderNull(object)
    else if wesabe.isUndefined(object)
      @_renderUndefined(object)
    else if wesabe.isArray(object)
      @_renderArray(object, refs)
    else if wesabe.isNumber(object)
      @_renderNumber(object)
    else if wesabe.isBoolean(object)
      @_renderBoolean(object)
    else if wesabe.isObject(object)
      @_renderObject(object, refs)
    else
      wesabe.error('could not identify type for: ', object);

  _renderString: (string) ->
    map = {"\n": "\\n", "\r": "\\r", "\t": "\\t", '"': '\\"', "\\": "\\\\"}
    result = ""

    for s in string
      result += if map.hasOwnProperty(s)
                  map[s]
                else if /[\u00FF-\uFFFF]/.test(s)
                  "\\u#{s.charCodeAt(0).toString(16)}"
                else
                  s

    return "\"#{result}\""

  _renderArray: (array, refs) ->
    refs.push(array);
    return "[#{(@_render(el, refs) for el in array).join(', ')}]"

  _renderBoolean: (bool) ->
    bool.toString()

  _renderObject: (object, refs) ->
    refs.push(object)
    attrs = []
    for own key, value of object
      value = @_render(value, refs)
      if value != undefined
        attrs.push("#{@_render(key, refs)}: #{value}")

    return "{#{attrs.join(', ')}}"

  _renderNumber: (number) ->
    number.toString()

  _renderNull: ->
    'null'

  _renderUndefined: ->
    'null'
