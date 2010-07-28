wesabe.require('xpath.Pathset');

var Assert = YAHOO.util.Assert;
var ArrayAssert = YAHOO.util.ArrayAssert;

var pathset_test_case = new YAHOO.tool.TestCase({
  name: "Pathset Tests",
  
  setUp: function() {
    var self = this;
    
    this.basicSet = new wesabe.xpath.Pathset('html', '//a');
    
    this.firstNode = document.createElement('div');
    this.set = new wesabe.xpath.Pathset();
    this.set.xpaths = [
      {first: function(){ return null }}, 
      {first: function(){ return self.firstNode }}, 
      {first: function(){ return null }}
    ];
    
    this.unboundSet = new wesabe.xpath.Pathset();
    this.unboundSet.xpaths = [
      {bind: function(){ return 'html' }}, 
      {bind: function(){ return '//a' }}
    ];
  }, 
  
  testConstructsWithAnArgumentList: function() {
    ArrayAssert.itemsAreEqual(['html', '//a'], new wesabe.xpath.Pathset('html', '//a').xpaths.map(function(p){return p.value}));
  }, 
  
  testConstructsWithAnArrayArgument: function() {
    ArrayAssert.itemsAreEqual(['html', '//a'], new wesabe.xpath.Pathset(['html', '//a']).xpaths.map(function(p){return p.value}));
  }, 
  
  testFirstReturnsFirstReturnedByAnyPathway: function() {with(this) {
    Assert.areSame(firstNode, set.first());
  }}, 
  
  testBindReturnsSetOfBoundedPathways: function() {with(this) {
    ArrayAssert.itemsAreEqual(['html', '//a'], unboundSet.bind().xpaths.map(function(p){return p.value}));
  }}, 
  
  testInspect: function() {with(this) {
    Assert.areEqual(
      '#<wesabe.xpath.Pathset xpaths=[#<wesabe.xpath.Pathway value="html">, #<wesabe.xpath.Pathway value="//a">]>', 
      basicSet.inspect()
    );
  }}
});
