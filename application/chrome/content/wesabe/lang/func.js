wesabe.provide('lang.func');

wesabe.lang.func = {
  /**
   * Calls the given function as if it had the keys in +scope+ as function 
   * parameters and the values of +scope+ as their values, using +context+ 
   * as "this" inside the function body. Example:
   * 
   *   var foo = function() { alert(bar) };
   *   
   *   // fails with "bar is not defined (ReferenceError)"
   *   foo();
   *   
   *   // alerts 4
   *   wesabe.lang.func.callWithScope(foo, this, {bar: 4});
   * 
   * IMPORTANT: Scope is ignored when called this way. Example:
   * 
   *   (function() {
   *     var bar = 4;
   *     var foo = function() { alert(bar) };
   *     
   *     // alerts 4
   *     foo();
   *     
   *     // fails with "bar is not defined (ReferenceError)"
   *    wesabe.lang.func.callWithScope(foo, this, {});
   *   })();
   */
  callWithScope: function(fn, context, scope) {
    var fn_body = wesabe.isString(fn) ?
      fn :
      fn.toString().match(/^[^\{]*\{((.*\n*)*)\}/m)[1];
    fn = new Function('__scope__', 'with(__scope__){\n' + fn_body + '\n}');
    return fn.call(context, scope);
  }, 
  
  /**
   * Executes a callback by name or, if only one callback was given, the 
   * single available callback. Example:
   * 
   *   wesabe.lang.func.executeCallback({
   *     success: function() { log('yay') }, 
   *     failure: function() { log('boo') }
   *   }, didItWork() ? 'success' : 'failure')
   * 
   * Note that for the construct above you really should use 
   * wesabe.callback instead:
   * 
   *   wesabe.callback({
   *     success: function() { log('yay') }, 
   *     failure: function() { log('boo') }
   *   }, didItWork())
   * 
   */
  executeCallback: function(callback, which, args) {
    return wesabe.tryThrow('executeCallback('+which+')', function() {
      var cb = callback && callback[which];
      cb = cb || callback;
      return wesabe.isFunction(cb) && cb.apply(cb, args);
    });
  }, 
  
  /**
   * Returns a function that will call the given function with the second argument 
   * as `this' inside the function. Example:
   * 
   *   var obj = {
   *     bar: 4, 
   *     
   *     foo: function() {
   *       return this.bar;
   *     }
   *   };
   *   
   *   var obj2 = {bar: 1};
   *   
   *   obj.foo();                               // => 4
   *   wesabe.lang.func.wrap(obj.foo, obj2);    // => 1
   * 
   */
  wrap: function(fn, self) {
    return function() { return fn.apply(self || fn, arguments) };
  }
};

wesabe.success = function(callback, args) {
  return wesabe.lang.func.executeCallback(callback, 'success', args);
};

wesabe.failure = function(callback, args) {
  return wesabe.lang.func.executeCallback(callback, 'failure', args);
};

wesabe.callback = function(callback, which, args) {
  return wesabe.lang.func.executeCallback(callback, which ? 'success' : 'failure', args);
};
