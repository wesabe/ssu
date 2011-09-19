# lazy-load privacy.untaint
untaint = (args...) ->
  {untaint} = require 'util/privacy'
  untaint args...


from = (object) ->
  item for item in object

uniq = (array) ->
  retval = []

  for item, i in array
    retval.push(item) unless include retval, item

  return retval

include = (array, object) ->
  # check without considering taintedness
  return true if object in array

  object = untaint object

  for item in array
    return true if untaint item is object

  return false

compact = (array) ->
  item for item in array when untaint item

equal = (a, b) ->
  return false if a.length isnt b.length

  for i in [0...a.length]
    return false if a[i] isnt b[i]

  return true

zip = (a, b) ->
  [a[i], b[i]] for i in [0...Math.max(a.length, b.length)]


module.exports = {from, uniq, include, compact, equal, zip}
