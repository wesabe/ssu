wesabe.require('util.proxy');

var Assert = YAHOO.util.Assert;

var proxy_test_case = new YAHOO.tool.TestCase({ 
  name: "Proxy Tests",
  
  setUp: function() {
    this.target = {};
    this.proxy = wesabe.util.proxy(this.target);
    
    this.arrayTarget = [];
    this.arrayProxy = wesabe.util.proxy(this.arrayTarget);
    
    this.stringTarget = "Hello there";
    this.stringProxy = wesabe.util.proxy(this.stringTarget);
    
    this.bodyProxy = wesabe.util.proxy(document.body);
  }, 
  
  // this would be nice, but we can't seem to fake equality
  // testAreConsideredEqual: function() {with(this) {
  //   Assert.areEqual(target, proxy);
  // }}, 
  
  testCanCallFunctionOnProxyTarget: function() {with(this) {
    target.test = function() { return 4 };
    Assert.areEqual(4, proxy.test());
  }}, 
  
  testCanCallFunctionsOnProxyTargetPrototype: function() {with(this) {
    Assert.areEqual(target.toString(), proxy.toString());
  }}, 
  
  testCanAccessGettersOnProxyTarget: function() {with(this) {
    Assert.areEqual(arrayTarget.length, arrayProxy.length);
  }}, 
  
  testCanProxyToDomNodes: function() {with(this) {
    Assert.areEqual(document.body.innerHTML, bodyProxy.innerHTML);
  }}
  
  // this doesn't seem to work on primitives like String, Number, etc  *sigh*
  // testCanOverrideFunctionsOnProxiesWithImmutableTargets: function() {with(this) {
  //   Assert.areEqual("there", stringProxy.substring(6));
  //   stringProxy.substring = function(){ return 'foo' };
  //   Assert.areEqual("foo", stringProxy.substring(6));
  // }}
});
