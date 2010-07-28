wesabe.require('logger.*');
wesabe.require('dom.page');

var Assert = YAHOO.util.Assert;

var page_test_case = new YAHOO.tool.TestCase({ 
  name: "Page Tests",
  
  setUp: function() {
    var self = this;
    
    this.node = document.body;
    this.input = document.createElement('input');
    this.absentXpath = '//input[@type="not-a-type"]';
    
    this.page = wesabe.dom.page.wrap(document);
    
    this.logOutput = document.getElementById('log_output');
  }, 
  
  testFindReturnsNodeWhenPassedNode: function() {with(this) {
    Assert.areSame(node, wesabe.dom.page.find(document, node));
  }}, 
  
  testFindReturnsFirstInDocumentWhenGivenXPath: function() {with(this) {
    Assert.areSame(node, wesabe.dom.page.find(document, '//body'));
  }}, 
  
  testFillSetsValueWhenItFindsNode: function() {with(this) {
    wesabe.dom.page.fill(document, input, 'foo');
    Assert.areEqual('foo', input.value);
  }}, 
  
  testFillFailsWhenItFindsNoNode: function() {with(this) {
    var failed = false;
    
    try { wesabe.dom.page.fill(document, absentXpath, 'foo') }
    catch(e) { failed = true }
    
    if (!failed) Assert.fail("Filling should have failed when given an xpath with no endpoints.")
  }}, 
  
  testVisible: function() {with(this) {
    Assert.isTrue(wesabe.dom.page.visible(document, input));
    input.style.display = 'none';
    Assert.isFalse(wesabe.dom.page.visible(document, input));
  }}, 
  
  testInvisibleContainer: function() {with(this) {
    try {
      Assert.isTrue(wesabe.dom.page.visible(document, logOutput));
      document.body.style.display = 'none';
      Assert.isFalse(wesabe.dom.page.visible(document, logOutput));
    } catch(e) {
      throw e;
    } finally {
      document.body.style.display = '';
    }
  }}, 
  
  testPresent: function() {with(this) {
    Assert.isTrue(wesabe.dom.page.present(document, document.body));
    Assert.isFalse(wesabe.dom.page.present(document, absentXpath));
  }}, 
  
  testWrappedObjectHasCustomMethods: function() {with(this) {
    Assert.isTypeOf('function', page.click);
  }}, 
  
  testWrappedObjectDoesNotHaveWrapMethod: function() {with(this) {
    Assert.isUndefined(page.wrap);
  }}, 
  
  testWrappedObjectActsLikeOriginal: function() {with(this) {
    Assert.areSame(document.body, page.body);
  }}
});
