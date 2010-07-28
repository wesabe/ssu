wesabe.provide('io.xhr');

wesabe.io.xhr.urlFor = function(path, params) {
  var url = path;
  if (params) {
    var qs = wesabe.io.xhr.encodeParams(params);
    if (qs.length) {
      url += (/\?/.test(url) ? '&' : '?')+qs;
    }
  }
  return url;
};

wesabe.io.xhr.encodeParams = function(params) {
  var qs = [];
  for (var k in params) {
    var v = params[k];
    if (!params.hasOwnProperty(k) || wesabe.isFunction(v)) continue;
    qs.push(encodeURIComponent(k)+'='+encodeURIComponent(v));
  }
  return qs.join('&');
};

wesabe.io.xhr.getUserAgent = function() {
  var runtime = "unknown";
  try {
    var appInfo =
      Components.classes["@mozilla.org/xre/app-info;1"].getService(Components.interfaces.nsIXULRuntime);
    runtime = appInfo.OS + " " + appInfo.XPCOMABI;
  } catch (ex) {}
  return "Wesabe-ServerSideUploader/" + wesabe.SSU_VERSION + " (" + runtime + ") Wesabe-API/1.0.0";
};

wesabe.io.xhr.request = function(method, path, params, data, callback) {
  var req = new XMLHttpRequest();

  var before = function() {
    // call `before' callback if it's given as a separate callback
    !wesabe.isFunction(callback) && wesabe.lang.func.executeCallback(callback, 'before', [req]);
    wesabe.trigger('before-xhr', [req]);
  };

  var after = function() {
    // call `after' callback if it's given as a separate callback
    !wesabe.isFunction(callback) && wesabe.lang.func.executeCallback(callback, 'after', [req]);
    wesabe.trigger('after-xhr', [req]);
  };

  return wesabe.tryThrow('xhr('+method+' '+path+')', function(log) {
    var contentType;

    if (params && !data && !method.match(/get/i)) {
      data = wesabe.isString(params) ?
        params :
        wesabe.io.xhr.encodeParams(params);
      params = null;
      contentType = "application/x-www-form-urlencoded";
    }

    var url = wesabe.io.xhr.urlFor(path, params);

    req.onreadystatechange = function() {
      wesabe.tryThrow('xhr('+method+' '+path+')/onreadystatechange', function(log) {
        log.debug('readyState=',req.readyState);
        if (req.readyState == 4) {
          log.debug('status=',req.status);
          wesabe.callback(callback, req.status == 200, [req]);
          after();
        }
      });
    };

    req.onerror = function(error) {
      wesabe.error('xhr('+method+' '+path+')/onerror: ', error);
      after();
    };

    log.debug('url=',url);
    req.open(method, url, true);
    // FIXME <brian@wesabe.com>: 2008-03-11
    // <hack>
    // XULRunner 1.9b3pre and 1.9b5pre insist on tacking on ";charset=utf-8" to whatever
    // Content-type header you might set using setRequestHeader, which USAA balks at.
    // To get around this you either have to pass in a DOMDocument or an nsIInputStream,
    // so this part is only here to work around that limitation. See:
    //   https://bugzilla.mozilla.org/show_bug.cgi?id=382947
    if (wesabe.isString(data)) {
      var stream = Components.classes['@mozilla.org/io/string-input-stream;1']
                      .createInstance(Components.interfaces.nsIStringInputStream);
      stream.setData(data, data.length);
      data = stream;
    }
    // </hack>
    contentType && req.setRequestHeader("Content-Type", contentType);
    req.setRequestHeader("User-Agent", wesabe.io.xhr.getUserAgent());
    req.setRequestHeader("Accept", "*/*, text/html");
    before();
    req.send(data);
    return req;
  });
};

wesabe.io.xhr.get = function(path, params, data, block) {
  return wesabe.io.xhr.request('GET', path, params, data, block);
};

wesabe.io.get = wesabe.io.xhr.get;

wesabe.io.xhr.post = function(path, params, data, block) {
  return wesabe.io.xhr.request('POST', path, params, data, block);
};

wesabe.io.post = wesabe.io.xhr.post;

wesabe.io.xhr.put = function(path, params, data, block) {
  return wesabe.io.xhr.request('PUT', path, params, data, block);
};

wesabe.io.put = wesabe.io.xhr.put;
