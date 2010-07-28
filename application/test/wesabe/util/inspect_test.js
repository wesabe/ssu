wesabe.require('util.inspect');

var Assert = YAHOO.util.Assert;

var inspect_test_case = new YAHOO.tool.TestCase({ 
  name: "Inspect Tests",
  
  setUp: function() {
    this.object = {foo: 'bar', n: 3.14};
    this.array = [1, 2, 'cat'];
    this.element = document.createElement('div');
    this.elementWithId = document.createElement('div');
    this.elementWithId.setAttribute('id', 'foo');
    this.elementWithClass = document.createElement('div');
    this.elementWithClass.setAttribute('class', 'hi there');
    this.elementWithIdAndClass = document.createElement('div');
    this.elementWithIdAndClass.setAttribute('id', 'foo');
    this.elementWithIdAndClass.setAttribute('class', 'hi there');
    this.textNode = document.createTextNode("hey there buddy\n");
  }, 
  
  testNumber: function() {
    Assert.areEqual('5', wesabe.util.inspect(5));
    Assert.areEqual('5.2', wesabe.util.inspect(5.2));
  }, 
  
  testNaN: function() {
    Assert.areEqual('NaN', wesabe.util.inspect(NaN));
  }, 
  
  testString: function() {
    Assert.areEqual('"foo"', wesabe.util.inspect('foo'));
    Assert.areEqual('"foo \\"bar\\""', wesabe.util.inspect('foo "bar"'))
  }, 
  
  testTaintedString: function() {
    Assert.areEqual('{sanitized "acnt #xxx-xxx-xxx"}', 
      wesabe.util.inspect(wesabe.taint('acnt #123-456-789')));
  }, 
  
  testNull: function() {
    Assert.areEqual('null', wesabe.util.inspect(null));
  }, 
  
  testUndefined: function() {
    Assert.areEqual('undefined', wesabe.util.inspect(undefined));
  }, 
  
  testTrue: function() {
    Assert.areEqual('true', wesabe.util.inspect(true));
  }, 
  
  testFalse: function() {
    Assert.areEqual('false', wesabe.util.inspect(false));
  }, 
  
  testArray: function() {with(this) {
    Assert.areEqual('[]', wesabe.util.inspect([]));
    Assert.areEqual('[1, 2, "cat"]', wesabe.util.inspect(array));
  }}, 
  
  testArrayWithSelfReference: function() {with(this) {
    array.push(array);
    Assert.areEqual('[1, 2, "cat", ...]', wesabe.util.inspect(array));
  }}, 
  
  testObject: function() {with(this) {
    Assert.areEqual('#<Object>', wesabe.util.inspect({}));
    Assert.areEqual('#<Object foo="bar" n=3.14>', wesabe.util.inspect(object));
  }}, 
  
  testObjectWithSelfReference: function() {with(this) {
    object.self = object;
    Assert.areEqual('#<Object foo="bar" n=3.14 self=...>', wesabe.util.inspect(object));
  }}, 
  
  testCustomInspect: function() {with(this) {
    object.inspect = function() { return 'foo' };
    Assert.areEqual('foo', wesabe.util.inspect(object));
  }}, 
  
  testElement: function() {with(this) {
    Assert.areEqual('<div>', wesabe.util.inspect(element));
  }}, 
  
  testElementWithId: function() {with(this) {
    Assert.areEqual('<div id="foo">', wesabe.util.inspect(elementWithId));
  }}, 
  
  testElementWithClass: function() {with(this) {
    Assert.areEqual('<div class="hi there">', wesabe.util.inspect(elementWithClass));
  }}, 
  
  testElementWithIdAndClass: function() {with(this) {
    Assert.areEqual('<div id="foo" class="hi there">', wesabe.util.inspect(elementWithIdAndClass));
  }}, 
  
  testTextNode: function() {with(this) {
    Assert.areEqual('{text "hey there buddy\\n"}', wesabe.util.inspect(textNode));
  }}
});
