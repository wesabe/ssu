wesabe.require('logger.*');
wesabe.require('download.*');

var Assert = YAHOO.util.Assert;

var download_controller_test_case = new YAHOO.tool.TestCase({ 
  name: "Download Controller Tests",
  
  setUp: function() {
    var self = this;
    
    var mockServer = {
      init: function(port, loopbackOnly, backLog) {
        this.port = port;
        this.loopbackOnly = loopbackOnly;
        this.backLog = backLog;
      }, 
      
      asyncListen: function(listener) {
        this.listener = listener;
      }
    };
    
    this.controller = new wesabe.download.Controller();
    this.controller.createServerSocket = function() { return mockServer };
  }, 
  
  testStartServer: function() {with(this) {
    controller.start(7777);
    Assert.areEqual(7777,       controller.server.port);
    Assert.areEqual(true,       controller.server.loopbackOnly);
    Assert.areEqual(-1,         controller.server.backLog);
    Assert.areEqual(controller, controller.server.listener);
  }}
});
