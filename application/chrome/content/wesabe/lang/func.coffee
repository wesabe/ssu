type                 = require 'lang/type'
{trim}               = require 'lang/string'
{tryCatch, tryThrow} = require 'util/try'

# Taken from https://github.com/mauricemach/coffeekup/blob/7eed6ea2bf404f36e1f9da51500969fe346428f3/src/coffeekup.coffee#L100
support = '''
  var __slice = Array.prototype.slice;
  var __hasProp = Object.prototype.hasOwnProperty;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  var __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype;
    return child;
  };
  var __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
'''

#
# Calls the given function as if it had the keys in +scope+ as function
# parameters and the values of +scope+ as their values, using +context+
# as "this" inside the function body. Example:
#
#   foo = -> alert(bar)
#
#   // fails with "bar is not defined (ReferenceError)"
#   foo();
#
#   // alerts 4
#   wesabe.lang.func.callWithScope foo, this, bar: 4
#
# IMPORTANT: Scope is ignored when called this way. Example:
#
#   (->
#     bar = 4
#     foo = -> alert(bar)
#
#     # alerts 4
#     foo()
#
#     # fails with "bar is not defined (ReferenceError)"
#     wesabe.lang.func.callWithScope foo, this, {}
#   )()
#
callWithScope = (fn, context, scope={}, args=[]) ->
  if type.isString fn
     body = fn
   else
     body = fn.toString().match(/^[^\{]*\{((.*\n*)*)\}/m)[1]
     argNames = fn.toString().match(/^function\s*\((.*)\)/)?[1].split(/\s*,\s*/)
     if argNames
       for name, i in argNames
         name = trim name
         scope[name] = args[i]

  return new Function('__scope__', support + "with(__scope__){\n#{body}\n}").call(context, scope)

#
# Executes a callback by name or, if only one callback was given, the
# single available callback. Example:
#
#   wesabe.lang.func.executeCallback({
#     success: function() { log('yay') },
#     failure: function() { log('boo') }
#   }, didItWork() ? 'success' : 'failure')
#
# Note that for the construct above you really should use
# wesabe.callback instead:
#
#   wesabe.callback({
#     success: function() { log('yay') },
#     failure: function() { log('boo') }
#   }, didItWork())
#
#
executeCallback = (callback, which, args) ->
  tryThrow "executeCallback(#{which})", ->
    cb = callback?[which] or callback
    cb?(args...)

#
# Returns a function that will call the given function with the second argument
# as `this' inside the function. Example:
#
#   obj =
#     bar: 4
#
#     foo: ->
#       @bar
#
#   obj2 = bar: 1
#
#   obj.foo()                    // => 4
#   func.wrap(obj.foo, obj2)()   // => 1
#
#
wrap = (fn, self) ->
  (args...) -> fn.call(self or fn, args...)


# shortcuts
wesabe.success = (callback, args) ->
  executeCallback callback, 'success', args

wesabe.failure = (callback, args) ->
  executeCallback callback, 'failure', args

wesabe.callback = (callback, which, args) ->
  executeCallback callback, (if which then 'success' else 'failure'), args


module.exports = {callWithScope, executeCallback, wrap}
