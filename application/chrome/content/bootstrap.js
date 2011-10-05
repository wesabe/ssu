(function() {
  var $dir, $file, Cc, Ci, bootstrap, functionNameForLine, getContent, indentCount;
  this.onerror = function(error) {
    return dump("unhandled error: " + error + "\n");
  };
  Cc = Components.classes;
  Ci = Components.interfaces;
  getContent = function(uri) {
    var cache, content, dir, i, line, liveFile, m, name, root;
    liveFile = $file.open($dir.chrome.path + ("/content/" + uri));
    if (!liveFile.exists()) {
      return null;
    }
    if (m = uri.match(/^(?:(.+)\/)?([^\/]+)\.coffee$/)) {
      name = m[2];
      dir = m[1];
      root = $dir.root;
      cache = $dir.mkpath(root, "tmp/script-build-cache/" + (dir || ''));
      cache.append("" + name + ".js");
      if (cache.exists() && cache.lastModifiedTime >= liveFile.lastModifiedTime) {
        return $file.read(cache);
      } else {
        dump("\x1b[36m[compile]\x1b[0m " + uri + "\n");
        content = $file.read(liveFile);
        content = ((function() {
          var _len, _ref, _results;
          _ref = content.split(/\n/);
          _results = [];
          for (i = 0, _len = _ref.length; i < _len; i++) {
            line = _ref[i];
            _results.push(line.replace(/__LINE__/, i + 1));
          }
          return _results;
        })()).join("\n");
        content = CoffeeScript.compile(content);
        $file.write(cache, content);
        return content;
      }
    }
    return $file.read(liveFile);
  };
  indentCount = function(line) {
    var i, indent;
    indent = 0;
    while (line.indexOf(((function() {
        var _results;
        _results = [];
        for (i = 0; 0 <= indent ? i <= indent : i >= indent; 0 <= indent ? i++ : i--) {
          _results.push('  ');
        }
        return _results;
      })()).join('')) === 0) {
      indent++;
    }
    return indent;
  };
  functionNameForLine = function(line) {
    var match;
    if (match = line.match(/([_a-zA-Z]\w*)\s*:\s*(?:__bind\()?function\s*\(/)) {
      return match[1];
    } else if (match = line.match(/function\s*([_a-zA-Z]\w*)\s*\([\)]*/)) {
      return match[1];
    } else if (match = line.match(/(\w+)\s*=\s*(?:__bind\()?function\b/)) {
      return match[1];
    } else if (match = line.match(/\w+\.([_a-zA-Z]\w*)\s*=\s*(?:__bind\()?function/)) {
      return match[1];
    } else if (match = line.match(/((?:get|set)\s+[_a-zA-Z]\w*)\(\)/)) {
      return match[1];
    } else if (match = line.match(/__define([GS]et)ter__\(['"]([_a-zA-Z]\w*)['"],\s*function/)) {
      return "" + (match[1].toLowerCase()) + " " + match[2];
    }
  };
  $file = {
    open: function(path) {
      var file;
      file = Cc['@mozilla.org/file/local;1'].createInstance(Ci.nsILocalFile);
      file.initWithPath(path);
      return file;
    },
    read: function(file) {
      var data, fiStream, path, siStream;
      if (typeof file === 'string') {
        path = file;
        file = $file.open(path);
      } else if (file) {
        path = file.path;
      }
      fiStream = Cc['@mozilla.org/network/file-input-stream;1'].createInstance(Ci.nsIFileInputStream);
      siStream = Cc['@mozilla.org/scriptableinputstream;1'].createInstance(Ci.nsIScriptableInputStream);
      fiStream.init(file, 1, 0, false);
      siStream.init(fiStream);
      data = siStream.read(-1);
      siStream.close();
      fiStream.close();
      return data;
    },
    write: function(file, data, mode) {
      var flags, foStream, path;
      if (typeof file === 'string') {
        path = file;
        file = $file.open(path);
      } else if (file) {
        path = file.path;
      }
      foStream = Cc['@mozilla.org/network/file-output-stream;1'].createInstance(Ci.nsIFileOutputStream);
      flags = mode === 'a' ? 0x02 | 0x10 : 0x02 | 0x08 | 0x20;
      foStream.init(file, flags, 0664, 0);
      foStream.write(data, data.length);
      foStream.close();
      return true;
    }
  };
  $dir = {
    create: function(dir) {
      if (typeof dir === 'string') {
        dir = $file.open(dir);
      }
      return dir.create(0x01, 0774);
    },
    mkpath: function(root, path) {
      var part, _i, _len, _ref;
      _ref = path.split(/[\/\\]/);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        part = _ref[_i];
        root.append(part);
        if (!root.exists()) {
          $dir.create(root);
        }
      }
      return root;
    }
  };
  $dir.__defineGetter__('chrome', function() {
    return Cc['@mozilla.org/file/directory_service;1'].createInstance(Ci.nsIProperties).get('AChrom', Ci.nsIFile);
  });
  $dir.__defineGetter__('root', function() {
    var root;
    root = $file.open($dir.chrome.path + '/../../');
    root.normalize();
    return root;
  });
  bootstrap = {
    loadedScripts: [],
    info: null,
    uri: 'bootstrap.js',
    evalOffset: null,
    currentOffset: null,
    getContent: getContent,
    load: function(uri, scope) {
      var content, lines, offset, padding;
      if (scope == null) {
        scope = {};
      }
      content = getContent(uri);
      lines = content.split('\n').length;
      offset = this.currentOffset;
      padding = new Array(offset - this.evalOffset + 1).join('\n');
      this.loadedScripts.push({
        uri: uri,
        content: content,
        offset: offset,
        lines: lines
      });
      this.currentOffset += lines;
      return (function() {
        with (scope) { eval(padding+content) };        return null;
      }).call(window);
    },
    infoForEvaledLineNumber: function(lineNumber) {
      var filename, indentOfLine, indentOfLineToCheck, line, lineNumberToCheck, lineToCheck, lines, minimumIndent, name, s, script, _i, _len, _ref, _ref2;
      script = this.info;
      _ref = this.loadedScripts;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        s = _ref[_i];
        if ((s.offset <= (_ref2 = lineNumber - 1) && _ref2 < s.offset + s.lines)) {
          script = s;
          break;
        }
      }
      filename = script.uri;
      lineNumber = lineNumber - script.offset;
      lines = script.content.split('\n');
      line = lines[lineNumber - 1];
      name = functionNameForLine(line);
      if (!name && line) {
        indentOfLine = indentCount(line);
        minimumIndent = indentOfLine;
        lineNumberToCheck = lineNumber - 2;
        while (lineNumberToCheck >= 0) {
          lineToCheck = lines[lineNumberToCheck];
          indentOfLineToCheck = indentCount(lineToCheck);
          if (indentOfLineToCheck < minimumIndent) {
            minimumIndent = indentOfLineToCheck;
            if (name = functionNameForLine(lineToCheck)) {
              break;
            }
          }
          lineNumberToCheck--;
        }
        name || (name = indentOfLine === 1 ? '(top)' : '(anonymous)');
      }
      return {
        filename: filename,
        lineNumber: lineNumber,
        line: line,
        name: name
      };
    }
  };
  (function() {
    var i, line, lines, _len;
    lines = (getContent(bootstrap.uri)).split('\n');
    for (i = 0, _len = lines.length; i < _len; i++) {
      line = lines[i];
      if (line.match(/\beval\(/) && !line.match(/CoffeeScript/)) {
        bootstrap.evalOffset = i;
        break;
      }
    }
    bootstrap.currentOffset = lines.length;
    return bootstrap.info = {
      uri: bootstrap.uri,
      content: lines.join('\n'),
      offset: 0,
      lines: lines.length
    };
  })();
  (function() {
    var s, scripts, src, _i, _len, _results;
    scripts = document.getElementsByTagName('script');
    _results = [];
    for (_i = 0, _len = scripts.length; _i < _len; _i++) {
      s = scripts[_i];
      if (s.getAttribute('type') === 'text/coffeescript') {
        _results.push((src = s.getAttribute('src')) ? bootstrap.load(src) : void 0);
      }
    }
    return _results;
  })();
  this.bootstrap = bootstrap;
  this.GLOBAL = this;
}).call(this);
