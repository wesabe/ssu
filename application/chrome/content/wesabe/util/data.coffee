uuid = 0
cache = {}
expando = "ssu#{new Date().getTime()}"

# shamelessly adapted from jQuery.data
data = (elem, name, data) ->
  id = elem[expando]

  # assign the id to elem
  id ||= elem[expando] = ++uuid

  # return early if we're just getting the id
  return id unless name

  cache[id] ||= {}

  # set the data if we're using it as a setter
  cache[id][name] = data unless data is undefined

  return cache[id][name]

remove = (elem, name) ->
  id = elem[expando]

  if not name
    # kill the whole cache for elem
    delete cache[id]

  else if cache[id]?[name]
    delete cache[id][name]

    cacheEmpty = true

    # anything left in the cache?
    for own name of cache[id]
      cacheEmpty = false
      break

    remove elem if cacheEmpty

data.remove = remove

module.exports = data
