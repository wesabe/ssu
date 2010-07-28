wesabe.require('lang.array');

var Assert = YAHOO.util.Assert;

var array_test_case = new YAHOO.tool.TestCase({ 
  name: "Array Tests",
  
  setUp: function() {
    this.array = [1, 2, 3, 4, 5, 'food'];
    this.nodeList = document.body.childNodes;
  }, 
  
  testFromArrayShouldEqualOriginal: function() {with(this) {
    YAHOO.util.ArrayAssert.itemsAreEqual(array, wesabe.lang.array.from(array));
  }}, 
  
  testFromArrayShouldHandleArgumentsPseudoArray: function() {with(this) {
    var f = function() {
      YAHOO.util.ArrayAssert.itemsAreEqual(array, wesabe.lang.array.from(arguments));
    };
    
    f(1, 2, 3, 4, 5, 'food');
  }}, 
  
  testFromArrayShouldHandleNodeLists: function() {with(this) {
    var nodes = [];
    for (var i = 0; i < nodeList.length; i++)
      nodes.push(nodeList[i]);
    YAHOO.util.ArrayAssert.itemsAreEqual(nodes, wesabe.lang.array.from(nodeList));
  }}, 
  
  testUniqueShouldRemoveDuplicates: function() {with(this) {
    YAHOO.util.ArrayAssert.itemsAreEqual([1, 2, 3], wesabe.lang.array.uniq([1, 2, 2, 3]));
  }}
});
