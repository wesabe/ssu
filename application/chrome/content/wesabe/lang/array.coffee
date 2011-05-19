wesabe.provide('lang.array')

wesabe.lang.array =
  from: (object) ->
    retval = []

    for o, i in object
      retval.push(o)

    return retval

  uniq: (array) ->
    retval = []

    for item, i in array
      retval.push(item) unless @include(retval, item)

    return retval

  include: (array, object) ->
    object = wesabe.untaint(object)

    for i, item in array
      return true if wesabe.untaint(array[i]) == object

    return false

  compact: (array) ->
    retval = []

    for i, item in array
      retval.push(item) if wesabe.untaint(item)

    return retval

  equal: (a, b) ->
    return false if a.length != b.length

    for i in a
      return false if a[i] != b[i]

    return true

  zip: (array1, array2) ->
    result = []

    for i in [0...Math.max(array1.length, array2.length)]
      result.push([array1[i], array2[i]])

    return result