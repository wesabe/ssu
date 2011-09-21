(function() {
  var bootstrap, getContent;
  this.onerror = function(error) {
    return dump("unhandled error: " + error + "\n");
  };
  getContent = function(uri) {
    var xhr, _ref;
    xhr = new XMLHttpRequest();
    xhr.open('GET', uri, false);
    try {
      xhr.send(null);
    } catch (e) {
      return null;
    }
    if ((_ref = xhr.status) === 0 || _ref === 200) {
      return xhr.responseText;
    } else {
      return null;
    }
  };
  bootstrap = {
    loadedScripts: [],
    info: null,
    uri: 'bootstrap.js',
    evalOffset: null,
    currentOffset: null,
    load: function(uri, scope) {
      var content, lines, offset, padding;
      if (scope == null) {
        scope = {};
      }
      content = getContent(uri);
      if (uri.match(/\.coffee$/)) {
        content = CoffeeScript.compile(content);
      }
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
      var filename, line, s, script, _i, _len, _ref, _ref2;
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
      line = script.content.split('\n')[lineNumber - 1];
      return {
        filename: filename,
        lineNumber: lineNumber,
        line: line
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
    bootstrap.info = {
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
}).call(this);
