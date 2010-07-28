wesabe.provide('util.inspect');

/**
 * Converts +object+ into a string representation suitable for debugging.
 * @method inspect
 * @param object {Object} The object to inspect.
 */
wesabe.util.inspect = function(object) {
  return wesabe.util._inspect(object, [], false);
};

wesabe.util.inspectForLog = function(object) {
  return wesabe.util._inspect(object, [], wesabe.logger && wesabe.logger.colorizeLogging);
};

/**
 * Generates an inspect function suitable for use in a class prototype.
 * @method inspectorFor
 * @param klass {String} The name of the class the function will be used with.
 */
wesabe.util.inspectorFor = function(klass) {
  return function() {
    return '#<' + klass + wesabe.util._inspectAttributes(this, [this]) + '>';
  }
}

/**
 * Internal logic for inspect.
 * @method _inspect
 * @param object {Object} The object to inspect.
 * @param refs {Array} The objects already inspected in this call to inspect.
 * @private
 */
wesabe.util._inspect = function(object, refs, color, tainted) {
  for (var i = 0; i < refs.length; i++)
    if (refs[i] === object) return '...';

  refs = refs.concat([object]);

  if (object && typeof object.inspect == 'function') return object.inspect(refs, color, tainted);

  var t = typeof object;

  if (wesabe.isTainted(object))               return wesabe.util._inspectTainted(object, refs, color);
  else if (t == 'function')                   return '#<Function>';
  else if (t == 'number')                     return object.toString();
  else if (object === null)                   return 'null';
  else if (t == 'undefined')                  return 'undefined';
  else if (object === true)                   return 'true';
  else if (object === false)                  return 'false';
  else if (t == 'string')                     return wesabe.util._inspectString(object, color, tainted);
  else if (object instanceof Array)           return '[' + object.map(function(o) { return wesabe.util._inspect(o, refs, color, tainted) }).join(', ') + ']';
  else if (object instanceof HTMLElement)     return wesabe.util._inspectElement(object, color, tainted);
  else if (object instanceof XULElement)      return wesabe.util._inspectElement(object, color, tainted);
  else if (object instanceof Window)          return wesabe.util._inspectWindow(object, color, tainted);
  else if (object instanceof RegExp)          return wesabe.util._inspectRegExp(object, color, tainted);
  else if (wesabe.isDate(object))             return wesabe.util._inspectString(object.toString(), color, tainted);
  else if (object.nodeType == Node.TEXT_NODE) return '{text ' + wesabe.util.inspect(object.nodeValue, tainted) + '}';
  else if ((object.constructor == Error) ||
           (object.constructor == TypeError) ||
           (object.constructor == ReferenceError) ||
           (object.constructor == InternalError) ||
           (object.constructor == SyntaxError) ||
           (object.message && object.location && object.filename)) return wesabe.util._inspectError(object, refs, color, tainted);
  else                                        return wesabe.util._inspectObject(object, refs, color, tainted);
};

wesabe.util._inspectError = function(error, refs, color, tainted) {
  var s = new wesabe.util.Colorizer();
  s.disabled = !color;
  s
    .reset()
    .print('An exception has occurred:\n    ')
    .red(error.message)
    .print(' (', error.name, ')\n')
    .print('Backtrace:\n');

  var trace = [], files = {};
  if (error.stack) {
    error.stack.replace(/([^\r\n]+)\@([^\@\r\n]+?):(\d+)([\r\n]|$)/g, function(everything, call, file, lineno) {
      trace.push({name: call, filename: file, lineNumber: lineno});
    });
  } else if (error.location) {
    var frame = error.location;
    while (frame) {
      trace.push(frame);
      frame = frame.caller;
    }
  }

  trace.forEach(function(frame) {
    var name=frame.name||'unknown', file=frame.filename||'unknown', lineno=frame.lineNumber||'??';

    var m = file.match(/^(.*\/)wesabe\.js$/);
    if (m) {
      var info = wesabe.fileAndLineFromEvalLine(parseInt(lineno));
      if (info && info.file != 'wesabe.js') {
        file = m[1] + info.file;
        lineno = info.lineno + ' (eval line ' + lineno + ')';
      }
    }

    m = file.match(/^chrome:\/\/[^\/]+\/content\/(.*)$/);
    if (m)
      file = m[1];

    var contents = files[file] || (files[file] = (wesabe._getText(file) || '').split(/\n/));
    if (contents && lineno != '??') {
      lineno = parseInt(lineno);
      for (var i = lineno; i < contents.length && i >= 0; i--) {
        m = contents[i].match(/([a-zA-Z]\w*)\s*:\s*function\s*\(|function\s*([a-zA-Z]\w*)\s*\([\)]*|((?:get|set)\s+[a-zA-Z]\w*)\(\)/);
        if (m) {
          name = m[1] || m[2] || m[3];
          break;
        }
      }
    }

    for (var i = 0; i < 40 - name.length; i++) s.print(' ');
    if (name.length >= 40) name = name.slice(0, 37) + '...';
    s.print(name, ' at ', file, ':', lineno, '\n');
  });

  return s.toString();
};

wesabe.util._inspectTainted = function(object, refs, color) {
  if (wesabe.logger.level == wesabe.logger.levels.radioactive) {
    // don't sanitize on radioactive
    return wesabe.util._inspect(object.untaint(), refs, color, false);
  } else {
    var s = new wesabe.util.Colorizer();
    s.disabled = !color;

    return s
      .bold('{sanitized ')
      .print(wesabe.util._inspect(object.untaint(), refs, color, true))
      .bold('}')
      .toString();
  }
};

wesabe.util._inspectObject = function(object, refs, color, tainted) {
  var s = new wesabe.util.Colorizer();
  s.disabled = !color;
  var modName = function(o, prefix) {
    var name = o && o.__module__ && o.__module__.fullName;
    return (name && prefix) ? (prefix+name) :
                       name ? name :
                              null;
  }

  return s
    .yellow('#<')
    .bold(modName(object, 'module:') || modName(object.constructor) || 'Object')
    .print(wesabe.util._inspectAttributes(object, refs, color, tainted))
    .yellow('>')
    .toString();
};

/**
 * Generates a string which could be re-eval'ed to get the original string.
 * @method _inspectString
 * @param string {String} The string to inspect.
 * @private
 */
wesabe.util._inspectString = function(string, color, tainted) {
  var s = new wesabe.util.Colorizer();
  s.disabled = !color;
  var map = {"\n": "\\n", "\t": "\\t", '"': '\\"', "\r": "\\r"};
  var value = string.replace(/(["\n\r\t])/g, function(s) {return map[s]});

  if (tainted) {
    value = wesabe.util.privacy.sanitize(value);
  }

  return s.yellow('"').green(value).yellow('"').toString();
};

wesabe.util._inspectRegExp = function(regexp, color, tainted) {
  var s = new wesabe.util.Colorizer();
  s.disabled = !color;

  return s.yellow(regexp.toSource()).toString();
};

/**
 * Generates a string inspecting the attributes of +object+.
 * @method _inspectAttributes
 * @param object {Object} The object whose attributes will be inspected.
 * @param refs {Array} The objects already inspected in this call to inspect.
 * @private
 */
wesabe.util._inspectAttributes = function(object, refs, color, tainted) {
  var s = new wesabe.util.Colorizer();
  s.disabled = !color;
  var pairs = [], keys = [];

  for (attr in object) {
    keys.push(attr);
  }

  keys.sort().forEach(function(key) {
    if (wesabe.isFunction(object[key]) || key.match(/^__/)) return;
    s
      .print(' ')
      .underlined(key)
      .yellow('=')
      .print(wesabe.util._inspect(object[key], refs, color, tainted));
  });

  return s.toString();
};

/**
 * Generate a string inspecting the given +element+.
 * @method _inspectElement
 * @param element {HTMLElement} The element to inspect.
 * @private
 */
wesabe.util._inspectElement = function(element, color, tainted) {
  var s = new wesabe.util.Colorizer();
  s.disabled = !color;
  s
    .yellow('<')
    .white()
    .bold()
    .print(element.tagName.toLowerCase())
    .reset();

  wesabe.lang.array.from(element.attributes).forEach(function(attr) {
    var value = attr.nodeValue.toString();
    if (tainted) {
      value = wesabe.util.privacy.sanitize(value);
    }

    s
      .print(' ')
      .underlined(attr.nodeName)
      .yellow('="')
      .green(value)
      .yellow('"');
  });
  return s.yellow('>').toString();
};

/**
 * Generate a string inspecting the given +window+.
 */
wesabe.util._inspectWindow = function(window, color, tainted) {
  var s = new wesabe.util.Colorizer();
  s.disabled = !color;

  return s
    .yellow('#<')
    .white()
    .bold()
    .print("Window ")
    .reset()
    .underlined('title')
    .yellow('=')
    .print(wesabe.util._inspectString(window.document.title,color,tainted))
    .yellow('>')
    .toString();
};
