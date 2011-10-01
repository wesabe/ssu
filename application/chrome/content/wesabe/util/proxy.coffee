#
# Generates a proxy to wrap +target+.
# @method proxy
# @param target {Object} the target to proxy to. DOESN'T WORK WITH PRIMITIVES
#
#    // you can use it just like the regular object
#    p = proxy([1, 2])
#    p.toString()  // => "12"
#
#    // you can also override things in the proxy without affecting the target
#    p.toString = -> "foo"
#    p.toString()  // => "foo"
#
#    // of course you can proxy to any JS object
#    p = proxy({})
#    p.toString()  // => "[object Object]"
#
#    // even DOM nodes
#    p = proxy(document.links[0])
#    p.innerHTML   // => "<span>Hello there</span>"
#
module.exports = (target) ->
  klass = ->
  klass.prototype = target
  proxy = new klass()
  proxy.proxyTarget = target
  return proxy
