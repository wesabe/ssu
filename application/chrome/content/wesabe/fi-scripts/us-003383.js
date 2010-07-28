wesabe.download.Player.register({
  fid: 'us-003383',
  org: 'American Express Cards',

  dispatchFrames: false,
  afterUpload: 'logout',

  includes: [
    'fi-scripts.us-003383.login',
    'fi-scripts.us-003383.accounts',
  ],

  dispatch: function() {
    if (page.present(e.errors.systemNotResponding)) {
      tmp.systemNotRespondingTTL = tmp.systemNotRespondingTTL || 4;
      tmp.systemNotRespondingTTL--;

      if (!tmp.systemNotRespondingTTL) {
        job.fail(503, 'fi.unavailable');
      } else {
        log.warn("Amex system is not responding (retrying, TTL=", tmp.systemNotRespondingTTL, ")");
        // retry again in 5s
        setTimeout(function(){ action.main() }, 15000);
      }
      return false;
    }
  },

  actions: {
    main: function() {
      wesabe.dom.browser.go(browser, "https://www.americanexpress.com/");
    },
  },

  elements: {
    errors: {
      systemNotResponding: [
        '//text()[contains(., "Our System is Not Responding")]',
      ],
    },
  },

  extensions: {
    start: function(answers, browser) {
      var self = this;

      var jobproxy = {
        update: function(status, result) {
          // proxy job updates through
          self.job.update(status, result);
        },

        fail: function(status, result) {
          wesabe.info("Could not complete job with OFX player (", status, " ", result, ") -- trying web based one");
          wesabe.download.Player.prototype.start.call(self, answers, browser);
        },

        succeed: function() {
          // the OFX version worked! we're done
          self.job.succeed();
        },

        timer: self.job.timer,
      };

      wesabe.info("Starting with OFX for American Express Cards");
      var ofxPlayer = new wesabe.download.OFXPlayer(self.fid);
      ofxPlayer.job = jobproxy;
      ofxPlayer.start(answers);
    },
  },
});
