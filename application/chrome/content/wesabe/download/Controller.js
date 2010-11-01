wesabe.provide('download.Controller');
wesabe.require('download.Player');
wesabe.require('canvas.snapshot');

wesabe.download.Controller = function() {
  var self = this;
  var job;

  this.createServerSocket = function() {
    return Components.classes['@mozilla.org/network/server-socket;1']
                    .createInstance(Components.interfaces.nsIServerSocket);
  };

  this.start = function(port) {
    var retriesLeft, bindSuccessful = false;

    if (port) {
      // bind only to a specific port
      retriesLeft = 0;
    } else {
      // start at 5000 and try up to 5100
      retriesLeft = 100;
      port = 5000;
    }

    return wesabe.tryCatch('Controller#start', function(log) {
      self.server = self.createServerSocket();
      while (!bindSuccessful && retriesLeft > 0) {
        try {
          self.server.init(port, true, -1);
          self.server.asyncListen(self);
          bindSuccessful = true;
        } catch (e) {
          log.warn('Failed to bind to port ', port, ', trying up to ', retriesLeft, ' more');
          port++; retriesLeft--;
        }
      }
      if (bindSuccessful) {
        log.info('Listening on port ', port);
        return port;
      } else {
        log.error("Failed to start listener");
      }
    });
  };

  this.onSocketAccepted = function(serv, transport) {
    wesabe.tryCatch('Controller#onSocketAccepted', function(log) {
      var outstream =
        transport.openOutputStream(Components.interfaces.nsITransport.OPEN_BLOCKING, 0, 0);

      var stream = transport.openInputStream(0, 0, 0);
      var instream = Components.classes['@mozilla.org/scriptableinputstream;1']
                              .createInstance(Components.interfaces.nsIScriptableInputStream);

      instream.init(stream);
      log.debug('Accepted connection');

      var pump = Components.classes['@mozilla.org/network/input-stream-pump;1']
                          .createInstance(Components.interfaces.nsIInputStreamPump);
      pump.init(stream, -1, -1, 0, 0, false);
      pump.asyncRead({
        onStartRequest: function(request, context) {
          log.radioactive(this);
          this.request = '';
        },
        onStopRequest: function(request, context, status) {
          log.radioactive(this);
          outstream.close();
        },
        onDataAvailable: function(request, context, inputStream, offset, count) {
          var data = instream.read(count), index;
          log.radioactive('getting data: ', data);
          this.request += data;

          while ((index = this.request.indexOf("\n")) != -1) {
            var requestText = this.request.substring(0, index);
            this.request = this.request.substring(index+1);

            var request      = wesabe.lang.json.parse(requestText);
            var response     = self.dispatch(request);
            var responseText;
            try {
              responseText = wesabe.lang.json.render(response)+"\n";
              log.radioactive(responseText);
              outstream.write(responseText, responseText.length);
            } catch (e) { wesabe.error(e) }
          }
        }
      }, null);
    });
  };

  this.onStopListening = function(serv, status) {
    wesabe.debug("Controller#onStopListening");
  };


  this.dispatch = function(request) {
    request.action = request.action.replace('.', '_');
    return wesabe.tryCatch('Controller#dispatch', function(log) {
      if (wesabe.isFunction(self[request.action])) {
        return self[request.action].call(self, request.body);
      } else {
        var message = "Unrecognized request action " + wesabe.util.inspect(request.action);
        log.error(message);
        return {response: {status: 'error', error: message}};
      }
    });
  };

  this.job_start = function(data) {
    wesabe.tryCatch('job.start', function(log) {
      if (typeof data != 'object'){
        throw new Error("Got unexpected type: "+(typeof data))
      }

      if (data.wesabe) {
        wesabe.api.authenticate(data.wesabe);
      } else if (data.jobid && data.user_id) {
        wesabe.api.authenticate(data);
      }

      if (data.api) {
        wesabe.util.prefs.set('wesabe.api.root', data.api);
      }

      job = new wesabe.download.Job(data.jobid, data.fid, data.creds, data.user_id, data.options);

      if (data.cookies) {
        wesabe.util.cookies.restore(data.cookies);
      }

      if (data.callback) {
        var callbacks = wesabe.isString(data.callback) ? [data.callback] : data.callback;
        if (callbacks.length) {
          wesabe.bind(job, 'update', function() {
            var params = {
              status: job.status,
              result: job.result,
              data: wesabe.lang.json.render(job.data),
              completed: job.done,
              cookies: wesabe.util.cookies.dump(),
              timestamp: new Date().getTime(),
              version: job.version,
            };

            callbacks.forEach(function(callback) {
              wesabe.io.put(callback, params);
            });
          });
        }
      }
      job.start();
    });
    return {response: {status: 'ok'}};
  };

  this.job_resume = function(data) {
    if (job) {
      try {
        job.resume(data.creds);
        return {response: {status: 'ok'}};
      } catch (e) {
        return {response: {status: 'error', error: e.toString()}};
      }
    } else {
      return {response: {status: 'error', error: "No running jobs"}};
    }
  };

  this.job_status = function(data) {
    if (job) {
      return {response:
        {status: 'ok',
         'job.status': {
           status: job.status,
           result: job.result,
           data: job.data,
           jobid: job.jobid,
           fid: job.fid,
           completed: job.done,
           cookies: wesabe.util.cookies.dump(),
           timestamp: new Date().getTime(),
           version: job.version}}};
    } else {
      return {response: {status: 'error', error: "No running jobs"}};
    }
  };

  this.statement_list = function(data) {
    var statements = wesabe.io.dir.profile;
    statements.append('statements');
    var list = [];

    if (statements.exists())
      list = wesabe.io.dir.read(statements).map(function(file) {
        return file.path.match(/\/([^\/]+)$/)[1];
      });

    return {response: {status: 'ok', 'statement.list': list}};
  };

  this.statement_read = function(data) {
    if (!data)
      return {response: {status: 'error', error: "statement id required"}};

    var statement = wesabe.io.dir.profile;
    statement.append('statements');
    statement.append(data);

    if (statement.exists())
      return {response: {status: 'ok', 'statement.read': wesabe.io.file.read(statement)}};

    return {response: {status: 'error', error: "No statement found with id="+data}};
  };

  this.job_stop = function(data) {
    wesabe.info('Got request to stop job, shutting down');
    if (!job.done) {
      // job didn't finish, so it failed
      job.fail(504, 'timeout.quit');
    }
    return {response: {status: 'ok'}};
  };

  this.xul_quit = function(data) {
    setTimeout(function(){ goQuitApplication() }, 1000);
    return {response: {status: 'ok'}};
  };

  /**
   * Create and send uploads from the console:
   *
   *    upload.create :wesabe => {:username => 'WESABE_USER', :password => 'WESABE_PASS'}, :path => '/path/to/file.ofx', :fid => 'us-003383'
   *
   */
  this.upload_create = function(data) {
    try {
      wesabe.info('Starting upload of file ', data.path,
                  ' for username ', data.wesabe.username,
                  ' at fid ', data.fid);
      wesabe.api.authenticate(data.wesabe);
      var uploader = new wesabe.api.Uploader(wesabe.io.file.read(data.path), data.fid, data.nofx ? {nofx: data.nofx} : null, null);
      uploader.upload();
      return {response: {status: 'ok'}};
    } catch(e) {
      wesabe.error('upload.create: error: ', e);
      return {response: {status: 'error', error: e.toString()}};
    }
  };

  this.page_dump = function(data) {
    try {
      return {response: {status: 'ok', 'page.dump': job.player.page.dump()}};
    } catch(e) {
      return {response: {status: 'error', error: e.toString()}};
    }
  };

  this.eval = function(data) {
    try {
      var script = data.script;
      if (/[;\n]/.test(script)) {
        script = "(function(){"+script+"})()";
      }
      script = "return "+script;
      var result = wesabe.lang.func.callWithScope(script, wesabe, {job: job});
      return {response: {status: 'ok', 'eval': wesabe.util.inspect(result)}};
    } catch(e) {
      wesabe.error('eval: error: ', e);
      return {response: {status: 'error', error: e.toString()}};
    }
  };

  this.ofx_dump = function(data) {
    wesabe.require('crypto.*');

    var OFXDumper = function(fi, username, password) {
      var self = this;

      self.dumpAll = function() {
        self.buildRequest().requestAccountInfo({
          success: function(response) {
            self.onGetAccounts(response);
          },

          failure: function(response) {
            wesabe.error("Unable to get list of accounts! response=", response);
          },
        });
      };

      self.onGetAccounts = function(response) {
        wesabe.debug("Got accounts=", response.accounts);
        self.accounts = response.accounts;
        self.processAccounts();
      };

      self.processAccounts = function() {
        wesabe.tryThrow("ofx.dump#processAccounts", function(log) {
          if (!self.accounts.length) {
            wesabe.debug("No more accounts!");
            return;
          }

          self.account = self.accounts.shift();

          // FIXME <brian@wesabe.com> 2009-01-20: Set number of days to an FI-specific amount.
          // This is taken from OFXPlayer.js which does this correctly by using an FI-specific
          // number of days. Usually 365 is okay, but some FIs barf if you ask for more than, say, 90.
          var dtstart = wesabe.lang.date.add(new Date(), -365 * wesabe.lang.date.DAYS);
          self.buildRequest().requestStatement(self.account, {dtstart: dtstart}, {
            success: function(response) {
              self.onDownloadComplete(response);
            },

            failure: function(response) {
              self.onDownloadFailure(response);
            },
          });
        });
      };

      self.onDownloadComplete = function(response) {
        wesabe.tryThrow("ofx.dump#onDownloadComplete", function(log) {
          log.info("Parsing OFX document");
          var ofxdoc = new wesabe.ofx.Document(response.text),
              path   = wesabe.io.dir.tmp.path+wesabe.io.dir.sep+wesabe.crypto.md5(response.text)+'.ofx',
              file   = wesabe.io.file.open(path);

          if (!file) {
            log.error("Unable to open file at path=", path);
          } else {
            log.info("Writing OFX document to disk (path=", file.path, ")");
            log.debug(ofxdoc);
            wesabe.io.file.write(file, response.text);
          }

          self.processAccounts();
        });
      };

      self.onDownloadFailure = function(response) {
        wesabe.error("Failed to download account! response=", response);

        self.processAccounts();
      };

      self.buildRequest = function() {
        return new wesabe.ofx.Request(fi, username, password);
      };
    };

    if (data.wesabe) {
      wesabe.api.authenticate(data.wesabe);
    }

    if (data.ofx) {
      new OFXDumper({ ofxUrl: data.ofxUrl, ofxOrg: data.ofxOrg, ofxFid: data.ofxFid }, data.creds.username, data.creds.password).dumpAll();
    } else if (data.fid) {
      wesabe.api.FinancialInstitution.find(data.fid, function(fi) {
        if (!fi || !fi.ofxUrl)
          return wesabe.error("Unable to get OFX info from wesabe.com or FI does not have OFX info");
        new OFXDumper(fi, data.creds.username, data.creds.password).dumpAll();
      });
    }

    return {response: {status: 'ok'}};
  };

  this.onStatementReceived = function(event, data) {
    wesabe.tryThrow('Controller#onStatementReceived', function(log) {
      var folder = wesabe.io.dir.profile;
      folder.append('statements');
      if (!folder.exists())
        wesabe.io.dir.create(folder);

      var statement = folder.clone();
      statement.append(new wesabe.ofx.UUID().toString());

      wesabe.io.file.write(statement, data);
    });
  }
};
