wesabe.provide('util.proxy')

#
# Generates a proxy to wrap +target+.
# @method proxy
# @param target {Object} the target to proxy to. DOESN'T WORK WITH PRIMITIVES
#
#    // you can use it just like the regular object
#    var p = wesabe.util.proxy([1, 2]);
#    p.toString();  // => "12"
#
#    // you can also override things in the proxy without affecting the target
#    p.toString = function() { return "foo" };
#    p.toString();  // => "foo"
#
#    // of course you can proxy to any JS object
#    p = wesabe.util.proxy({});
#    p.toString();  // => "[object Object]"
#
#    // even DOM nodes
#    p = wesabe.util.proxy(document.links[0]);
#    p.innerHTML;   // => "<span>Hello there</span>"
#
wesabe.util.proxy = (target) ->
  klass = ->
  klass.prototype = target
  proxy = new klass()
  proxy.proxyTarget = target
  return proxy
