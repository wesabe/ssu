wesabe.provide('api.FinancialInstitution');

wesabe.api.FinancialInstitution = function(fid) {
  this.fid = fid;
};

wesabe.api.FinancialInstitution.prototype.refresh = function(callback) {
  var self = this;
  wesabe.api.get('/financial-institutions/'+this.fid, {format: 'xml'}, null, {
    success: function(request) {
      var fi = request.responseXML.firstChild;
      var node = function(name) {
        var el = fi.getElementsByTagName(name)[0];
        return el && el.textContent;
      };
      self.org           = node('name');
      self.ofxOrg        = node('ofx-org');
      self.ofxFid        = node('ofx-fid');
      self.ofxUrl        = node('ofx-url');
      self.ofxBroker     = node('ofx-broker');
      self.homepageUrl   = node('homepage-url');
      self.loginUrl      = node('login-url');
      self.passwordLabel = node('password-label');
      self.usernameLabel = node('username-label');
      wesabe.success(callback, [self]);
    }, 
    
    failure: function() {
      wesabe.failure(callback);
    }
  });
};

wesabe.api.FinancialInstitution.find = function(fid, callback) {
  var fi = new wesabe.api.FinancialInstitution(fid);
  fi.refresh(callback);
  return fi;
};
