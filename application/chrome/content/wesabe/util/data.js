wesabe.provide('util.data');

// shamelessly adapted from jQuery.data
wesabe.util.data = function(elem, name, data) {
  var id = elem[wesabe.util.data.expando], cache = wesabe.util.data.cache;
  
  // assign the id to elem
  if (!id)
    id = elem[wesabe.util.data.expando] = ++wesabe.util.data.uuid;
  
  // only create the cache if we're accessing/setting
  if (name && !cache[id])
    cache[id] = {};
  
  // don't overwrite with undefined
  if (data != undefined)
    cache[id][name] = data;
  
  return name ?
    cache[id][name] :
    id;
};

wesabe.util.data.remove = function(elem, name) {
  var id = elem[wesabe.util.data.expando], cache = wesabe.util.data.cache;
  
  if (name) {
    if (cache[id][name]) {
      delete cache[id][name];
      
      name = '';
      
      // anything left in the cache?
      for (name in cache[id])
        break;
      
      // nope? delete it
      if (!name)
        wesabe.util.data.remove(elem);
    }
  } else {
    // kill the whole cache for elem
    delete cache[id]
  }
};

wesabe.lang.extend(wesabe.util.data, {
  expando: "wesabe" + (new Date()).getTime(), 
  cache: {}, 
  uuid: 0
});
