wesabe.provide('download.OFXPlayer');
wesabe.require('ofx.*');


/* public methods */


wesabe.download.OFXPlayer = function(fid) {
  this.fid = fid;
};

wesabe.download.OFXPlayer.prototype.DAYS_OF_HISTORY = 365;

wesabe.download.OFXPlayer.register = function(params) {
  var klass = function() {
    // inherit from OFXPlayer
    wesabe.lang.extend(this, wesabe.download.OFXPlayer.prototype);
    // subclass it
    wesabe.lang.extend(this, params);
  };

  // make sure we put it where wesabe.require expects it
  wesabe['fi-scripts'][params.fid] = klass;

  return klass;
};

/**
 * Starts retrieving statements from the FI's OFX server.
 */
wesabe.download.OFXPlayer.prototype.start = function(creds) {
  var self = this;
  this.creds = creds;

  if (self.fi) {
    self.beginGetAccounts();
    return;
  }

  wesabe.api.FinancialInstitution.find(this.fid, {
    success: function(fi) {
      wesabe.debug('Got FI info: ', fi);
      self.fi = fi;
      self.org = fi.org;

      // do some sanity checking to make sure we can actually speak OFX to this FI
      if (fi.ofxUrl) {
        if (!fi.ofxFid) wesabe.warn("OFX fid is not set");
        if (!fi.ofxOrg) wesabe.warn("OFX org is not set");

        self.beginGetAccounts();
      } else {
        wesabe.error("Financial institution "+fi.org+" ("+fi.fid+") does not support the OFX protocol");
        self.job.fail(400, 'fi.unsupported');
        return;
      }
    },

    failure: function() {
      // couldn't get the FI information from PFC
      self.job.fail(500, 'ssu.pfc-error');
    }
  });
};

/**
 * An opportunity to do post-processing, called by Job.
 */
wesabe.download.OFXPlayer.prototype.finish = function() {
  // no-op
};


/* private methods */

/**
 * Gets the list of accounts from the FI, called by #start.
 */
wesabe.download.OFXPlayer.prototype.beginGetAccounts = function() {
  var self = this;

  // tell the user we're logging in
  this.job.update('auth.creds');

  this.buildRequest().requestAccountInfo({
    success: function(response) {
      self.onGetAccounts(response);
    },

    failure: function(response) {
      self.onGetAccountsFailure(response);
    }
  });
};

/**
 * Handles the response containing the account list.
 */
wesabe.download.OFXPlayer.prototype.onGetAccounts = function(response) {
  this.job.update('account.list');

  this.accounts = wesabe.taint(response.accounts);
  wesabe.debug('accounts=', this.accounts);

  if (!this.accounts.length)
    wesabe.warn('There are no accounts! This might not be right...');

  // start downloading accounts in serial
  this.processAccounts();
};

/**
 * Handles a failure to get the account list.
 */
wesabe.download.OFXPlayer.prototype.onGetAccountsFailure = function(response) {
  wesabe.error('Error retrieving list of accounts!');
  this.onOFXError(response, function() {
    wesabe.warn("Document did not contain an OFX error, so just give up.");
    this.job.fail(503, 'fi.unavailable');
  });
};

/**
 * Processes the next account in the list (FIFO). Called after the
 * accounts list is retrieved and after each upload until there are no
 * more accounts.
 */
wesabe.download.OFXPlayer.prototype.processAccounts = function() {
  var self = this,
      job = self.job,
      options = job.options || {};

  job.update('account.download');
  wesabe.tryThrow('OFXPlayer#processAccounts', function(log) {
    if (!self.accounts.length) {
      // no more accounts, we're done
      job.succeed();
      return;
    }

    self.account = self.accounts.shift();
    var dtstart = options.since ? new Date(options.since) :
                  wesabe.lang.date.add(new Date(), -self.DAYS_OF_HISTORY * wesabe.lang.date.DAYS);

    self.buildRequest().requestStatement(self.account, {dtstart: dtstart}, {
      before: function() {
        // tell anyone who cares that we're starting to download an account
        job.update('account.download');
        job.timer.start('Download');
      },

      success: function(response) {
        self.onDownloadComplete(response);
      },

      failure: function(response) {
        self.onDownloadFailure(response);
      },

      after: function(response) {
        job.timer.end('Download');
      }
    });
  });
};

/**
 * Skips the current account and continues with the rest.
 */
wesabe.download.OFXPlayer.prototype.skipAccount = function() {
  var args;
  if (arguments.length) {
    args = arguments;
  } else {
    args = ["Skipping account=", this.account];
  }
  wesabe.warn.apply(wesabe, args);
  delete this.account;
  this.processAccounts();
};

/**
 * Handles an unsuccessful OFX response.
 */
wesabe.download.OFXPlayer.prototype.onOFXError = function(response, callback) {
  wesabe.error(response.text);
  if (response.ofx) {
    if (response.ofx.isGeneralError()) {
      this.job.fail(503, 'fi.unavailable');
      return;
    } else if (response.ofx.isAuthenticationError()) {
      this.job.fail(401, 'auth.creds.invalid');
      return;
    } else if (response.ofx.isAuthorizationError()) {
      this.job.fail(403, 'auth.noaccess');
      return;
    }
    // doh! didn't recognize any status
  } else {
    // wow, this wasn't even an OFX error, it was some sort of
    // HTTP error or something. sometimes happens when passing
    // data to the FI that it didn't expect causing them to
    // send back a 500 Internal Server Error
  }
  // couldn't make sense of what the FI said
  wesabe.isFunction(callback) && callback.call(this);
};

/**
 * Handles an OFX response containing a statement to be imported.
 */
wesabe.download.OFXPlayer.prototype.onDownloadComplete = function(response) {
  wesabe.trigger('downloadSuccess', [response.statement]);

  // done with this account
  this.account.completed = true;
  delete this.account;
  // now do the rest
  this.processAccounts();
};

/**
 * Handles a failure to get a statement.
 */
wesabe.download.OFXPlayer.prototype.onDownloadFailure = function(response) {
  wesabe.error('Error retrieving statement for account=', this.account);
  if (response.ofx && response.ofx.isGeneralError()) {
    // Document contained a general error, which often means that they had trouble
    // getting a specific account (or it's not available for download via OFX,
    // yet they list it anyway). Maybe it's ephemeral, maybe not. The prevailing
    // wisdom right now is to just skip the account and go on with our lives.
    wesabe.warn("General error while downloading account: ", response.text);
    this.skipAccount();
  } else {
    // some more serious/unknown error
    this.onOFXError(response, function() {
      // called when there's no clear way to handle the response
      wesabe.warn("Document did not contain an OFX error!");
      this.skipAccount();
    });
  }
};

/**
 * Returns a new Request instance ready to be used.
 */
wesabe.download.OFXPlayer.prototype.buildRequest = function() {
  return new wesabe.ofx.Request(this.fi, this.creds.username, this.creds.password, this.job);
};
