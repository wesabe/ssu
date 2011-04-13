/* Helper class to contain status messages from the OFX response. */
wesabe.provide('ofx.Status', function(code, status, message) {
  this.code    = code;
  this.status  = status;
  this.message = message;
});

wesabe.lang.extend(wesabe.ofx.Status.prototype, {
  isSuccess: function() {
    if (this.code != "0" && this.code != "1") {
      return false;
    } else {
      return true;
    }
  },

  isError: function() {
    return !this.isSuccess();
  },

  isGeneralError: function() {
    return this.code === '2000';
  },

  isAuthenticationError: function() {
    return this.code === '15500';
  },

  isAuthorizationError: function() {
    return this.code === '15000' || this.code === '15502';
  },

  isUnknownError: function() {
    return this.isError() && !this.isGeneralError() && !this.isAuthenticationError() && !this.isAuthorizationError();
  },
});

wesabe.ready('wesabe.util.privacy', function() {
  wesabe.util.privacy.registerTaintWrapper({
    detector: function(o){ return wesabe.is(o, wesabe.ofx.Status) },
    getters: ["code", "status", "message"]
  });
});
