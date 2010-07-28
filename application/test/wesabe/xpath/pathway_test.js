wesabe.require('xpath.Pathway');

var Assert = YAHOO.util.Assert;

var pathway_test_case = new YAHOO.tool.TestCase({ 
  name: "Pathway Tests",
  
  setUp: function() {
    var self = this;
    
    this.xpath = 'html/head/title';
    
    this.anchorPathway = new wesabe.xpath.Pathway('//a');
    this.unboundAnchorPathway = new wesabe.xpath.Pathway('//a[@title=":title" or @alt=":title"]');
    this.unboundAnchorPathway2 = new wesabe.xpath.Pathway('//a[position()=:position or @title=":title"]');
    
    this.bodyPathway = new wesabe.xpath.Pathway('//body');
    
    this.anchorPathset = new wesabe.xpath.Pathset(this.anchorPathway, this.unboundAnchorPathway, this.unboundAnchorPathway2);
    
    this.anchor = document.createElement('a');
    this.mockDocumentWithResults = {evaluate: function(){ return {iterateNext: function(){ return self.anchor }} }};
    this.mockDocumentWithoutResults = {evaluate: function(){ return null }};
  }, 
  
  testPreservesValue: function() {with(this) {
    Assert.areEqual('//a', anchorPathway.value);
  }}, 
  
  testInspectsProperly: function() {with(this) {
    Assert.areEqual('#<wesabe.xpath.Pathway value="//a">', anchorPathway.inspect());
  }}, 
  
  testAgainstRealDocument: function() {with(this) {
    Assert.areSame(document.body, bodyPathway.first(document));
  }}, 
  
  testCanReturnTheFirstMatchingNode: function() {with(this) {
    Assert.areEqual(anchor, anchorPathway.first(mockDocumentWithResults));
  }}, 
  
  testReturnsNullIfNoResultsAreFound: function() {with(this) {
    Assert.isNull(anchorPathway.first(mockDocumentWithoutResults));
  }}, 
  
  testBind: function() {with(this) {
    Assert.areEqual('//a[@title="Wesabe" or @alt="Wesabe"]', unboundAnchorPathway.bind({title: 'Wesabe'}).value);
    Assert.areEqual('//a[position()=2 or @title="Wesabe"]', unboundAnchorPathway2.bind({title: 'Wesabe', position: 2}).value);
  }}, 
  
  testConvertFromString: function() {with(this) {
    Assert.areEqual(xpath, wesabe.xpath.Pathway.from(xpath).value);
  }}, 
  
  testConvertFromPathway: function() {with(this) {
    Assert.areSame(anchorPathway, wesabe.xpath.Pathway.from(anchorPathway));
  }}, 
  
  testConvertFromPathset: function() {with(this) {
    Assert.areSame(anchorPathset, wesabe.xpath.Pathway.from(anchorPathset));
  }}, 
  
  testConvertFromNumberShouldFail: function() {with(this) {
    var failed = false;
    
    try { wesabe.xpath.Pathway.from(2) }
    catch(e) { failed = true }
    
    if (!failed) fail('Converting from 2 to a Pathway should have failed.');
  }}
});
