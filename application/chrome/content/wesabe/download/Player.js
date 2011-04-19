wesabe.provide('fi-scripts');
wesabe.require('logger.*');
wesabe.require('dom.*');
wesabe.require('xul.UserAgent');

wesabe.provide('download.Player', function() { });

wesabe.download.Player.register = function(params) {
  var klass = this.create(params);

  // make sure we put it where wesabe.require expects it
  wesabe.provide('fi-scripts.'+klass.fid, klass);

  return klass;
};

wesabe.download.Player.create = function(params) {
  var klass = function() {
    // inherit from Player
    wesabe.lang.extend(this, wesabe.download.Player.prototype, false);
  };

  // the method that decides based on the state of the job and page what to do next
  klass.prototype.dispatches = [];
  // the elements we need to recognize
  klass.elements = {};
  // any dispatch filters
  klass.prototype.filters = [];
  // any download callbacks
  klass.prototype.afterDownloadCallbacks = [];
  // after last goal callbacks
  klass.prototype.afterLastGoalCallbacks = [];
  // any alert callbacks
  klass.prototype.alertReceivedCallbacks = [];
  // the Wesabe Financial Institution ID (e.g. us-001078)
  klass.fid = klass.prototype.fid = params.fid;
  // the name of the Financial Institution (e.g. Wells Fargo)
  klass.org = klass.prototype.org = params.org;
  // ofx info in case this is a hybrid
  klass.ofx = params.ofx;

  var modules = [params];

  if (params.includes) {
    params.includes.forEach(function(include) {
      try {
        modules.push(wesabe.require(include));
      } catch (ex) {
        throw new Error("Error while requiring " + include + " -- check that the file exists and has the correct 'provide' line");
      }
    });
  }

  // dispatchFrames: false
  if (wesabe.isFalse(params.dispatchFrames)) {
    klass.prototype.filters.push(function() {
      if (page.defaultView.frameElement)
        return false;
    });
  }

  // userAgent: "Mozilla/4.0 HappyFunBrowser"
  if (params.userAgent) {
    klass.prototype.userAgent = params.userAgent;
  }

  // userAgentAlias: "Firefox"
  if (params.userAgentAlias) {
    klass.prototype.userAgent = wesabe.xul.UserAgent.getByNamedAlias(params.userAgentAlias);
  }

  modules.forEach(function(module) {
    if (module.dispatch) {
      klass.prototype.dispatches.push(module.dispatch);
    }

    if (module.elements) {
      wesabe.lang.extend(klass.elements, module.elements);
    }

    if (module.actions) {
      wesabe.lang.extend(klass.prototype, module.actions);
    }

    if (module.extensions) {
      wesabe.lang.extend(klass.prototype, module.extensions);
    }

    if (module.afterDownload) {
      klass.prototype.afterDownloadCallbacks.push(module.afterDownload);
    }

    if (module.afterLastGoal) {
      klass.prototype.afterLastGoalCallbacks.push(module.afterLastGoal);
    }

    if (module.alertReceived) {
      klass.prototype.alertReceivedCallbacks.push(module.alertReceived);
    }

    if (module.filter) {
      klass.prototype.filters.push(module.filter);
    }
  });

  return klass;
};

wesabe.download.Player.prototype.start = function(answers, browser) {
  var self = this;

  if (this.userAgent) {
    wesabe.xul.UserAgent.set(this.userAgent);
  } else {
    wesabe.xul.UserAgent.revertToDefault();
  }

  // set up the callbacks for page load and download done
  wesabe.bind(browser, 'DOMContentLoaded', function(event) {
    self.onDocumentLoaded(browser, wesabe.dom.page.wrap(event.target));
  });

  wesabe.bind('downloadSuccess', function(event) {
    self.job.update('account.download.success');
    self.setErrorTimeout('global');
    self.onDownloadSuccessful(browser, wesabe.dom.page.wrap(browser.contentDocument));
  });

  wesabe.bind('downloadFail', function(event) {
    wesabe.warn('Failed to download a statement! This is bad, but a failed job is worse, so we press on');
    self.job.update('account.download.failure');
    self.setErrorTimeout('global');
    self.onDownloadSuccessful(browser, wesabe.dom.page.wrap(browser.contentDocument));
  });

  this.setErrorTimeout('global');
  // start the security question timeout when the job is suspended
  wesabe.bind(this.job, 'suspend', function() {
    self.clearErrorTimeout('action');
    self.clearErrorTimeout('global');
    self.setErrorTimeout('security');
  });
  wesabe.bind(this.job, 'resume', function() {
    self.clearErrorTimeout('security');
    self.setErrorTimeout('global');
  });

  this.answers = answers;
  this.runAction('main', browser);
};

wesabe.download.Player.prototype.nextGoal = function() {
  this.job.nextGoal();
};

wesabe.download.Player.prototype.onLastGoalFinished = function() {
  wesabe.info('Finished all goals, running callbacks');
  for (var i = 0; i < this.afterLastGoalCallbacks.length; i++) {
    this.runAction(this.afterLastGoalCallbacks[i], this.browser, this.page);
  }
};

wesabe.download.Player.prototype.finish = function() {
  this.clearErrorTimeout('action');
  this.clearErrorTimeout('global');
  this.clearErrorTimeout('security');
};

wesabe.download.Player.prototype.runAction = function(name, browser, page, scope) {
  var self = this, module = this.constructor.fid;
  var fn = wesabe.isFunction(name) ? name : this[name];
  var name = wesabe.isFunction(name) ? (name.name || '(anonymous)') : name;

  this.job.timer.end('Navigate');

  if (!fn) throw new Error("Cannot find action '"+name+"'! Typo? Forgot to include a file?");

  var retval = wesabe.tryThrow(module+'#'+name, function(log) {
    var url = page && wesabe.taint(page.defaultView.location.href);
    var title = page && wesabe.taint(page.title);

    return self.job.timer.start('Action', function() {
      self.setErrorTimeout('action');
      self.history.push({name: name, url: url, title: title});
      wesabe.info('History is ', self.history.map(function(hi){ return hi.name }).join(' -> '));

      return wesabe.lang.func.callWithScope(fn, self, wesabe.lang.extend({
        browser: browser,
           page: page,
              e: self.constructor.elements,
        answers: self.answers,
        options: self.job.options,
            log: log,
            tmp: self.tmp,
         action: self.getActionProxy(browser, page),
            job: self.getJobProxy(),
    skipAccount: self.skipAccount,
         reload: function(){ self.onDocumentLoaded(browser, page) },
      }, scope||{}));
    });
  });

  this.job.timer.start('Navigate', {overlap: false});

  return retval;
};

wesabe.download.Player.prototype.resume = function(answers) {
  var self = this;
  if (wesabe.isArray(answers)) {
    answers.forEach(function(answer) {
      self.answers[answer.key] = answer.value;
    });
  } else if (wesabe.isObject(answers)) {
    // TODO: 2008-11-24 <brian@wesabe.com> -- this is only here until the new style (Array) is in PFC and SSU Service
    wesabe.lang.extend(this.answers, answers);
  }
  this.onDocumentLoaded(this.browser, this.page);
};

wesabe.download.Player.prototype.getActionProxy = function(browser, page) {
  var action = function(){}, self = this;
  action.__noSuchMethod__ = function(method, args) {
    self.runAction(method, browser, page);
  };
  return action;
};

wesabe.download.Player.prototype.getJobProxy = function() {
  return this.job;
};

/**
 * Answers whatever security questions are on the page by
 * using the xpaths given in e.security.
 */
wesabe.download.Player.prototype.answerSecurityQuestions = function() {

  var questions = page.select(e.security.questions);
  var qanswers  = page.select(e.security.answers);

  if (questions.length != qanswers.length) {
    wesabe.error("Found ", questions.length, " security questions, but ",
      qanswers.length, " security question answers to fill");
    wesabe.error("questions = ", questions);
    wesabe.error("qanswers = ", qanswers);
    return false;
  }

  if (!questions.length) {
    wesabe.error("Failed to find any security questions");
    return false;
  }

  questions = questions.map(function(q){ return wesabe.lang.string.trim(q.nodeValue) });

  wesabe.info("Found security questions: ", questions);
  questions = wesabe.untaint(questions);

  var data = {questions: []};
  for (var i = 0; i < questions.length; i++) {
    var question = questions[i];
    var answer   = answers[question];
    var element  = qanswers[i];

    if (answer) {
      page.fill(element, answer);
    } else {
      log.debug("element = ", element, " -- element.type = ", element.type);
      data.questions.push({key: question, label: question, persistent: true, type: wesabe.untaint(element.type) || "text"});
    }
  }

  if (data.questions.length) {
    job.suspend('suspended.missing-answer.auth.security', data);
    return false;
  }

  job.update('auth.security');

  // choose to bypass the security questions if we can
  if (e.security.setCookieCheckbox) page.check(e.security.setCookieCheckbox);
  if (e.security.setCookieSelect) page.fill(e.security.setCookieSelect, e.security.setCookieOption);
  // submit the form
  page.click(e.security.continueButton);

  return true;
};

/**
 * Fills in the date range for a download based on a lower bound.
 *
 * ==== Options (options)
 * :since<Number, null>::
 *   Time of the lower bound to use for the date range (in ms since epoch).
 *
 * @public
 */
wesabe.download.Player.prototype.fillDateRange = function() {
  var formatString = e.download.date.format || 'MM/dd/yyyy';

  var opts   = e.download.date;
  var fromEl = wesabe.untaint(page.find(opts.from));
  var toEl   = wesabe.untaint(page.find(opts.to));

  var from, to;

  function getDefault(defaultValue, existing) {
    if (wesabe.isFunction(defaultValue))
      defaultValue = defaultValue(existing);
    if (defaultValue)
      return wesabe.lang.date.parse(defaultValue);
  }

  if (toEl) {
    to = wesabe.dom.date.forElement(toEl, formatString);
    // use default or today's date if we can't get a date from the field
    if (!to.date)
      to.date = getDefault(opts.defaults && opts.defaults.to) || new Date();

    log.info("Adjusting date upper bound: ", to.date);
  }

  if (fromEl) {
    // if there's a lower bound, choose a week before it to ensure some overlap
    var since = options.since && (options.since - 7 * wesabe.lang.date.DAYS);

    // get a date if there's already one in the field
    from = wesabe.dom.date.forElement(fromEl, formatString);

    if (from.date && since) {
      // choose the most recent of the pre-populated date and the lower bound
      from.date = new Date(Math.max(since, from.date.getTime()));
    } else if (since) {
      // choose the lower bound
      from.date = new Date(since);
    } else if (to) {
      // pick the default or an 89 day window
      from.date = getDefault(opts.defaults && opts.defaults.from, {to: to.date}) ||
        wesabe.lang.date.add(to.date, -89 * wesabe.lang.date.DAYS);
    }

    log.info("Adjusting date lower bound: ", from.date);
  }
};


wesabe.download.Player.prototype.nextAccount = function() {
  delete tmp.account;
  reload();
};


wesabe.download.Player.prototype.skipAccount = function() {
  if (arguments.length) wesabe.warn.apply(wesabe, arguments);
  delete this.tmp.account;
};

wesabe.download.Player.prototype.actionTimeoutDuration = 60000; // 1m
wesabe.download.Player.prototype.globalTimeoutDuration = 300000; // 5m
wesabe.download.Player.prototype.securityTimeoutDuration = 180000; // 3m

wesabe.download.Player.prototype.setErrorTimeout = function(type) {
  var self = this, duration = this[type+'TimeoutDuration'];
  var tt = this._timeouts;
  if (!tt) tt = this._timeouts = {};

  this.clearErrorTimeout(type);

  wesabe.debug("Timeout ", type, " set (",duration,")");

  tt[type] = setTimeout(function() {
    wesabe.trigger(self, 'timeout', [type]);
    if (self.job.done) return;
    wesabe.error("Timeout ",type," (",duration,") reached, abandoning job");
    wesabe.tryCatch("Player#setErrorTimeout(page dump)", function() {
      if (self.page) self.page.dumpPrivately();
    });
    self.job.fail(504, 'timeout.'+type);
  }, duration);
};

wesabe.download.Player.prototype.clearErrorTimeout = function(type) {
  var tt = this._timeouts;
  if (tt && tt[type]) {
    wesabe.debug("Timeout ", type, " cleared");
    clearTimeout(tt[type]);
  }
};

wesabe.download.Player.prototype.onDocumentLoaded = function(browser, page) {
  if (this.job.done || this.job.paused) return;
  var self = this, module = this.constructor.fid;

  // log when alert and confirm are called
  new wesabe.dom.Bridge(page.proxyTarget, function() {
    this.evaluate(
      // evaluated on the page
      function() {
        window.alert = function(message){ callback('alert', message); return true };
        window.confirm = function(message){ callback('confirm', message); return true };
      },
      // evaluated here
      function(data) {
        var type = data[0], message = data[1];
        if (type == "alert") {
          wesabe.info(type, ' called with message=', wesabe.util.inspectForLog(message));
          if (self.alertReceivedCallbacks) {
            self.alertReceivedCallbacks.forEach(function(callback) {
              wesabe.lang.func.callWithScope(callback, self, {
                message: message,
                browser: browser,
                   page: page,
                      e: self.constructor.elements,
                answers: self.answers,
                options: self.job.options,
                    log: wesabe,
                     go: go,
                    tmp: self.tmp,
                 action: self.getActionProxy(browser, page),
                    job: self.getJobProxy(),
                 reload: function(){ self.onDocumentLoaded(browser, page) },
            skipAccount: self.skipAccount,
              });
            });
          }
        }
      });
  });

  if (!this.shouldDispatch(browser, page)) {
    wesabe.info('skipping document load');
    return;
  }

  this.triggerDispatch(browser, page);
};

wesabe.download.Player.prototype.triggerDispatch = function(browser, page) {
  var self = this, module = this.constructor.fid;

  browser = browser || this.browser;
  page = page || this.page;

  var url = wesabe.taint(page.defaultView.location.href);
  var title = wesabe.taint(page.title);

  wesabe.info('url=', url);
  wesabe.info('title=', title);

  wesabe.trigger(this, 'page-load', [browser, page]);

  // these should not be used inside the FI scripts
  this.browser = browser;
  this.page = page;

  var go = function(name) {
    self.runAction(name, browser, page);
  };

  this.job.timer.start('Sleep', {overlap: false});

  setTimeout(function() {
    if (self.job.done || self.job.paused) return;
    var result;

    for (var i = 0; i < self.dispatches.length; i++) {
      wesabe.tryThrow(module+'#dispatch('+i+')', function(log) {
        self.job.timer.start('Dispatch', {overlap: false});

        result = wesabe.lang.func.callWithScope(self.dispatches[i], self, {
          browser: browser,
             page: page,
                e: self.constructor.elements,
          answers: self.answers,
          options: self.job.options,
              log: log,
               go: go,
              tmp: self.tmp,
           action: self.getActionProxy(browser, page),
              job: self.getJobProxy(),
           reload: function(){ self.onDocumentLoaded(browser, page) },
      skipAccount: self.skipAccount,
        });
      });

      if (wesabe.isFalse(result)) {
        wesabe.info("dispatch chain halted");
        return;
      }
    }
  }, 2000);
};

wesabe.download.Player.prototype.onDownloadSuccessful = function(browser, page) {
  for (var i = 0; i < this.afterDownloadCallbacks.length; i++) {
    this.runAction(this.afterDownloadCallbacks[i], browser, page);
  }
};

wesabe.download.Player.prototype.shouldDispatch = function(browser, page) {
  var self = this;

  for (var i = 0; i < this.filters.length; i++) {
    var result = wesabe.tryCatch(this.constructor.fid+'#filter('+i+')', function(log) {
      var r = wesabe.lang.func.callWithScope(self.filters[i], self, {
        browser: browser,
           page: page,
              e: self.constructor.elements,
            log: log,
            tmp: self.tmp,
            job: self.getJobProxy(),
    skipAccount: self.skipAccount,
      });

      if (wesabe.isTrue(r)) {
        log.debug("forcing dispatch");
      } else if (wesabe.isFalse(r)) {
        log.debug("aborting dispatch");
      }

      return r;
    });

    // check for a definite answer
    if (wesabe.isBoolean(result)) return result;
  }

  wesabe.debug("no filter voted to force or abort dispatch, so forcing dispatch by default");
  return true;
};

wesabe.download.Player.prototype.__defineGetter__('history', function() {
  return this._history = this._history || [];
});

wesabe.download.Player.prototype.__defineGetter__('tmp', function() {
  return this._tmp = this._tmp || {};
});

wesabe.download.Player.build = function(fid) {
  return wesabe.tryThrow('download.Player.build(fid=' + fid + ')', function(log) {
    var klass;

    wesabe.tryThrow('loading fi-scripts.'+fid, function() {
      klass = wesabe.require('fi-scripts.' + fid);
    });

    return new klass(fid);
  });
};
