wesabe.download.Player.register({
  fid: 'us-003396',
  org: 'Chase',

  dispatchFrames: false,
  afterDownload: 'nextAccount',

  includes: [
    'fi-scripts.us-003396.promos',
    'fi-scripts.us-003396.login',
    'fi-scripts.us-003396.identification',
    'fi-scripts.us-003396.accounts',
    'fi-scripts.us-003396.errors',
  ],

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

      wesabe.info("Starting with OFX for Chase");
      var ofxPlayer = new wesabe.download.OFXPlayer(self.fid);
      ofxPlayer.job = jobproxy;
      ofxPlayer.start(answers);
    },
  },
});
