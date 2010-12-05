wesabe.provide('download.CompoundPlayer', function() {});

wesabe.lang.extend(wesabe.download.CompoundPlayer, {
  register: function(params) {
    var klass = this.create(params);

    // make sure we put it where wesabe.require expects it
    wesabe['fi-scripts'][params.fid] = klass;

    return klass;
  },

  create: function(params) {
    return function() {
      // inherit from OFXPlayer
      wesabe.lang.extend(this, wesabe.download.CompoundPlayer.prototype);
      // subclass it
      wesabe.lang.extend(this, params);
    };
  },
});

wesabe.lang.extend(wesabe.download.CompoundPlayer.prototype, {
  playerIndex: -1,
  currentJob: null,
  players: null,

  start: function(answers, browser) {
    var self = this;

    function startNextPlayer() {
      self.playerIndex++;
      self.currentPlayer = new self.players[self.playerIndex]();
      wesabe.info("Starting player ", self.currentPlayer);
      self.currentPlayer.job = jobProxy;
      self.currentPlayer.start(answers, browser);
    }

    var jobProxy = {
      update: function(status, result) {
        // proxy job updates through
        self.job.update(status, result);
      },

      fail: function(status, result) {
        wesabe.info("Could not complete job with ", self.currentJob, " (", status, " ", result, ")");

        if (self.playerIndex+1 < self.players.length) {
          startNextPlayer();
        } else {
          // no more players to try, report the last failure
          self.job.fail(status, result);
        }
      },

      succeed: function() {
        self.job.succeed();
      },

      timer: self.job.timer,

      get page() {
        return self.currentPlayer.page;
      },
    };

    startNextPlayer();
  },

  resume: function() {
    self.currentPlayer && self.currentPlayer.resume();
  },
});
