/**
 * Provides the basic methods needed to load packages and any functions
 * useful enough to live in the core.
 *
 * NOTE: Much of the package stuff is drawn from Dojo, which is a project
 * that is arguably over-engineered and generally stuffy, but hopefully
 * taking a small slice out of it will not spread the seeds of doom.
 */
var wesabe = {
  /**
   * Creates nested modules as given by the module.
   *
   * ==== Parameters
   * module<String>::
   *   The dot-separated name of the module/class that
   *   will be created somewhere after calling this.
   *
   * ==== Returns
   * Object:: The existing or newly created module specified by the argument.
   *
   * ==== Example
   *    wesabe.provide("math.Vector");
   *    wesabe.math.Vector = function() { ... };
   *
   * @private
   */
  provide: function(module, value) {
    var parts = module.split('.'), base = wesabe;

    for (var i = 0; i < parts.length-1; i++) {
      if (!base[parts[i]]) base[parts[i]] = {};
      base = base[parts[i]];
    }
    base[parts[parts.length-1]] = value || {};

    if (value) {
      value.__module__ = {
        name: parts[parts.length-1],
        fullName: module
      };
    }

    return base;
  },

  /**
   * Takes a callback to be run once the given module has been loaded.
   *
   * ==== Parameters
   * module<String>:: The dot-separated name of the module/class to watch for.
   * callback<Function>:: A function to call when the module is ready.
   *
   * ==== Example
   *   wesabe.ready("util.privacy", function() {
   *     wesabe.util.privacy.registerSanitizer(...);
   *   });
   *
   * @public
   */
  ready: function(module, callback) {
    var test = function(module) {
      module = module.replace(/^wesabe\./, '');
      var parts = module.split('.'), base = wesabe;

      for (var i = 0; i < parts.length; i++) {
        if (!base[parts[i]]) return false;
        base = base[parts[i]];
      }

      // the __module__ part is only available when it's done loading
      return base.__module__;
    };

    var run = function(module) {
      if (test(module)) {
        // got it, fire the callback
        wesabe.tryCatch('ready('+module+') callback', callback);
      } else {
        wesabe.debug('still waiting for ', module);
        // not yet, try again in 50ms
        setTimeout(function(){ run(module) }, 50);
      }
    };

    run(module);
  },

  /**
   * Loads a file in an attempt to load the specified module/class.
   *
   * ==== Parameters
   * module<String>:: The dot-separated name of the module/class to load.
   *
   * ==== Returns
   * Object:: The module, if it could be loaded.
   *
   * ==== Raises
   * Error:: If the file couldn't be loaded, an error is thrown.
   *
   * ==== Example
   *   // looks for files in this order:
   *   // wesabe/math/vector.js
   *   // wesabe/math.js
   *   // wesabe/math/__package__.js
   *   wesabe.require("math.vector");
   *
   *   // specifying an asterisk last changes the order:
   *   // wesabe/math/vector/__package__.js
   *   // wesabe/math/vector.js
   *   // wesabe/math.js
   *   // wesabe/math/__package__.js
   */
  require: function(module) {
    // split "A.B" into ["A", "B"]
    module = wesabe._parseModuleUri(module);

    if (module.object) return module.object;

    var uris = wesabe._getUrisForParts(module.parts, module.scheme);

    for (var i = 0; i < uris.length; i++) {
      var uri = uris[i];

      if (wesabe._loadUri(uri)) {
        base = wesabe;
        module.parts.forEach(function(part) {
          try { base = base[part] }
          catch (e) {
            var message = 'require: failed to get part '+part+' of module '+module.name;
            dump(message+'\n');
            throw new Error(message);
          }
        });
        base.__module__ = {
          name: module.parts[module.parts.length-1],
          fullName: module.name,
          uri: uri
        };
        return base;
      }
    }

    throw new Error("Failed to load " + module.name + ". Are you sure the files are in the right place?");
  },

  _parseModuleUri: function(module) {
    var m = module.match(/^(?:([-\w]+):\/\/)?([-\w\.\/]+?(?:\.\*)?)$/);
    if (!m) throw new Error("Parsing module uri '" + module + "' failed");

    var scheme = m[1] || 'chrome', path = m[2];
    var parts = path.split(/[\.\/]/), base;
    var result = {scheme: scheme, name: module, parts: parts};

    if (parts[parts.length-1] != '*') {
      base = wesabe;
      parts.forEach(function(part) { if (base) base = base[part] });
      result.object = base;
    }

    return result;
  },

  baseUrlForScheme: function(scheme) {
    if (!wesabe._baseUris) wesabe._baseUris = {};
    if (!wesabe._baseUris[scheme]) {
      try {
        var result = document.evaluate('//*[contains(@src, "wesabe.js")]', document, null, XPathResult.ANY_TYPE, null, null);
        var script = result && result.iterateNext();

        if (!script) throw "Could not determine the base url for the scripts. make sure this file is named wesabe.js.";
        wesabe._baseUris[scheme] = script.getAttribute('src').replace(/\.js$/, '');
      } catch (e) { dump("baseUrlForScheme: " + e + "\n") }
    }

    return wesabe._baseUris[scheme];
  },

  /**
   * Transforms an array of module parts to a list of possible Uris.
   * @method _getUrisForParts
   * @param parts {Array} The list of module parts.
   * @param lookForPackages {Boolean} Whether to look for a package file at all.
   * @param preferPackages {Boolean} Whether to look for a package file first.
   * @private
   */
  _getUrisForParts: function(parts, scheme, lookForPackages, preferPackages) {
    var s = wesabe.baseUrlForScheme(scheme);
    var u = function(pp) { var base = [s].concat(pp).join('/'); return [base + '.js', base + '.coffee']; };

    if (parts.length == 0) {
      return [];
    }
    if (parts[parts.length-1] == '*') {
      parts.pop();
      lookForPackages = preferPackages = true;
    }

    var uris = [];
    // A/B/C/__package__.{js,coffee}
    if (lookForPackages) {
      uris = uris.concat(u(parts.concat(['__package__'])));
    }
    // A/B/C.{js,coffee}
    if (preferPackages) {
      uris = uris.concat(u(parts));
    } else {
      uris = u(parts).concat(uris)
    }
    // start over with A/B
    return uris.concat(wesabe._getUrisForParts(parts.slice(0, parts.length-1), scheme, true, false));
  },

  /**
   * All the Uris loaded by _loadUri.
   * @private
   */
  _loadedUris: [],

  /**
   * File offset in number of lines.
   */
  _locOffset: null,

  /**
   * The line number of the eval statement in this file.
   */
  _evalOffset: null,

  /**
   * Returns the file and line number that the evaled code at a given line is from.
   */
  fileAndLineFromEvalLine: function(lineno) {
    for (var i = 0; i < wesabe._loadedUris.length; i++) {
      var uri = wesabe._loadedUris[i];
      if (lineno > uri.offset && lineno <= uri.offset+uri.loc)
        return {file: uri.file, lineno: lineno-uri.offset};
    }
  },

  /**
   * Loads (and evals) the JS file at +uri+. Returns true on success.
   * @method _loadUri
   * @param uri {String} The uri to the JS file to load and eval.
   * @private
   */
  _loadUri: function(uri) {
    if (wesabe._loadedUris[uri]) {
      return true;
    }

    var contents = wesabe._getEvalText(uri);
    if (!contents)
      return false;

    // figure out LOC offset and EVAL offset
    if (wesabe._locOffset === null) {
      var lines = wesabe._getEvalText(wesabe.getMyURI()).split(/\n/);
      for (var i = 0; i < lines.length; i++) {
        // can't actually use the same value we're looking for, or this'll be found first
        if (/_{2}EVAL_{2}/.test(lines[i])) {
          wesabe._evalOffset = i;
          break;
        }
      }
      wesabe._locOffset = lines.length;
      wesabe._loadedUris[wesabe.getMyURI()] = {offset: 0, loc: lines.length, file: wesabe.getMyURI()};
      wesabe._loadedUris.push(wesabe._loadedUris[wesabe.getMyURI()]);
    }

    var loc = contents.split(/\n/).length;

    wesabe._loadedUris[uri] = {offset: wesabe._locOffset, loc: loc, file: uri};
    wesabe._loadedUris.push(wesabe._loadedUris[uri]);

    var __FILE__ = uri;
    var padding = (new Array(wesabe._locOffset-wesabe._evalOffset+1)).join('\n');
    wesabe._locOffset += loc;

    try {
      eval(padding + contents + '\r\n//@ sourceUri=' + uri); // __EVAL__
    } catch (e) {
      dump('!! Error while evaluating code from '+uri+': '+e+'\n');
      dump('\n\n'+contents+'\n\n');
    }

    return true;
  },

  getMyURI: function() {
    if (wesabe._myURI) return wesabe._myURI;
    var scripts = document.getElementsByTagName('script');
    for (var i = 0; i < scripts.length; i++) {
      if (scripts[i].getAttribute('src').match(/wesabe.js$/)) {
        return wesabe._myURI = scripts[i].getAttribute('src');
      }
    }
  },

  /**
   * Gets the text at the given uri.
   * @method _getText
   * @param uri {String} The uri to the file to get the text of.
   * @private
   */
  _getText: function(uri) {
    var xhr = new XMLHttpRequest();

    xhr.open('GET', uri, false);
    try { xhr.send(null) }
    catch(e) { /* uh oh, 404? */ return null }

    return (xhr.status === 200 || xhr.status === 0) ? xhr.responseText : null;
  },

  _evalTextByURI: {},

  _getEvalText: function(uri) {
    if (this._evalTextByURI[uri])
      return this._evalTextByURI[uri];

    var text = this._getText(uri);

    if (!text)
      return text;

    if (/\.coffee$/.test(uri))
    {
      try { text = CoffeeScript.compile(text); }
      catch (e)
      {
        dump('!! Unable to compile CoffeeScript file '+uri+': '+e+'\n');
        return null;
      }
    }

    return this._evalTextByURI[uri] = text;
  },

  /**
   * Tries to run the given method, logging an error on an exception.
   * @method tryCatch
   * @return Returns the value returned by +callback+.
   */
  tryCatch: function(name, callback) {
    try {
      wesabe.debug('BEGIN ', name);
      var result = callback(wesabe.log4 && wesabe.log4(name));
      wesabe.debug('END   ', name);
      return result;
    } catch(ex) { wesabe.error(name, ': error: \n', ex); }
  },

  /**
   * Tries to run the given method, logging an error and rethrowing on an exception.
   * @method tryThrow
   * @return Returns the value returned by +callback+.
   */
  tryThrow: function(name, callback) {
    try {
      wesabe.debug('BEGIN ', name);
      var result = callback(wesabe.log4 && wesabe.log4(name));
      wesabe.debug('END   ', name);
      return result;
    } catch(ex) { wesabe.error(name, ': error: \n', ex); throw ex; }
  },

  get SSU_VERSION() {
    if (!wesabe.__ssu_version__) {
      wesabe.require('io.*');

      wesabe.__ssu_version__ =
        wesabe.__readDeployRevision__() || wesabe.__readGitRevision__() || 'unknown';
    }

    return wesabe.__ssu_version__;
  },

  __readDeployRevision__: function() {
    var revfile = wesabe.io.file.open(wesabe.io.dir.root.path + '/REVISION');
    if (revfile && revfile.exists()) {
      return wesabe.io.file.read(revfile).substring(0, 7);
    }
  },

  __readGitRevision__: function() {
    var gitroot = wesabe.io.file.open(wesabe.DEPLOY_ROOT + '/.git');
    if (!gitroot || !gitroot.exists()) return;

    // we're in a git repo
    var headfile = gitroot.clone();
    headfile.append('HEAD');
    if (!headfile.exists()) {
      wesabe.debug(".git/HEAD does not exist, so we're not in a git repo");
      return;
    }

    // we've got a HEAD file
    var head = wesabe.io.file.read(headfile);
    var m = head && head.match(/^ref: (.+?)\s*$/);
    if (!m || !m[1]) {
      wesabe.debug(".git/HEAD is not a recognizable format: ", wesabe.util.inspect(head));
      return;
    }

    // HEAD points to something
    var reffile = gitroot.clone();
    m[1].split('/').forEach(function(part){ reffile.append(part) });
    if (!reffile.exists()) {
      wesabe.debug(".git/HEAD pointed to ", m[1], " but that isn't a valid ref (.git/HEAD = ", head, ")");
      return;
    }

    // that something exists, so read it
    return wesabe.io.file.read(reffile).substring(0, 7);
  },
};
