from = (object) ->
  item for item in object

uniq = (array) ->
  retval = []

  for item, i in array
    retval.push(item) unless include retval, item

  return retval

include = (array, object) ->
  object = wesabe.untaint(object)

  for item in array
    return true if wesabe.untaint(item) is object

  return false

compact = (array) ->
  item for item in array when wesabe.untaint(item)

equal = (a, b) ->
  return false if a.length isnt b.length

  for i in [0...a.length]
    return false if a[i] isnt b[i]

  return true

zip = (a, b) ->
  [a[i], b[i]] for i in [0...Math.max(a.length, b.length)]

module.exports = {from, uniq, include, compact, equal, zip}
