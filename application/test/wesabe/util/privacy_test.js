wesabe.require('util.privacy');

var Assert = YAHOO.util.Assert;

Assert.isTainted = function(string) {
  Assert.isTrue(wesabe.isTainted(string), 
  "expected <" + wesabe.util.inspect(string) + "> to be tainted");
};

var privacy_test_case = new YAHOO.tool.TestCase({ 
  name: "Privacy Tests",
  
  setUp: function() {
    this.untaintedString = "OMG ACCNT #s 123-456-789";
    this.taintedString = wesabe.util.privacy.taint(this.untaintedString);
    this.sanitizedUntaintedString = "OMG ACCNT #s xxx-xxx-xxx";
    
    this.untaintedElement = document.getElementById('log_output');
    this.taintedElement = wesabe.util.privacy.taint(this.untaintedElement);
    
    this.untaintedTextNode = document.createTextNode('hey there');
    this.taintedTextNode = wesabe.util.privacy.taint(this.untaintedTextNode);
  }, 
  
  testTaintedStringStringOpsReturnTaintedString: function() {with(this) {
    Assert.isTainted(taintedString.substring(0, 1));
  }}, 
  
  testTaintedStringGetsProperLength: function() {with(this) {
    Assert.areEqual(untaintedString.length, taintedString.length);
  }}, 
  
  testTaintedStringMatchReturnsArrayOfTaintedStrings: function() {with(this) {
    taintedString.match(/^(\w+?)\s+(\w+)/).forEach(function(part) {
      Assert.isTainted(part);
    });
  }}, 
  
  testTaintedStringToStringReturnsSanitizedUntaintedString: function() {with(this) {
    Assert.areSame(sanitizedUntaintedString, taintedString.toString());
  }}, 
  
  testTaintedElementReturnsTaintedAttributes: function() {with(this) {
    var id = taintedElement.getAttribute('id')
    Assert.isTainted(id);
    Assert.areEqual(untaintedElement.getAttribute('id'), id.untaint());
  }}, 
  
  testTaintedElementReturnsTaintedGetter: function() {with(this) {
    var firstChild = taintedElement.firstChild;
    Assert.isTainted(firstChild);
    Assert.areEqual(untaintedElement.firstChild, firstChild.untaint());
    Assert.isTrue(firstChild.untaint() instanceof Element);
  }}, 
  
  testTaintedTextNodeReturnsTaintedNodeValue: function() {with(this) {
    var nodeValue = taintedTextNode.nodeValue;
    Assert.isTainted(nodeValue);
    Assert.areEqual(untaintedTextNode.nodeValue, nodeValue.untaint());
  }}
});
