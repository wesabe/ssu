wesabe.require('api.Uploader');
wesabe.require('api.FinancialInstitution');
wesabe.require('io.xhr');

wesabe.api.urlFor = function(path, params) {
  var url = wesabe.util.url.join(wesabe.util.prefs.get('wesabe.api.root'), path);
  return wesabe.io.xhr.urlFor(url, params);
};

wesabe.api.authenticate = function(creds) {
  // TODO <brian@wesabe.com> 2008-02-04: this should actually ping wesabe
  wesabe.api._creds = creds;
};

wesabe.api.request = function(method, path, params, data, callback) {
  return wesabe.tryThrow('api.request', function(log) {
    var url = wesabe.api.urlFor(path, params);
    var creds = wesabe.api._creds;
    
    // use job/user auth if we have them
    if (creds && creds.jobid && creds.user_id) {
      url = wesabe.api.urlFor(url, {job_guid: creds.jobid, user_id: creds.user_id});
    }
    
    return wesabe.io.xhr.request(method, url, null, data, {
      before: function(request) {
        // use basic auth if we have the user/pass
        if (creds && creds.username && creds.password) {
          request.setRequestHeader("Authorization", "Basic "+btoa(creds.username+":"+creds.password));
        }
        request.setRequestHeader("Content-type", "application/xml");
        request.setRequestHeader("Accept", "*/*, application/xml");
        if (!wesabe.isFunction(callback)) wesabe.lang.func.executeCallback(callback, 'before', [request]);
      }, 
      
      success: function(request) {
        wesabe.success(callback, [request]);
      }, 
      
      failure: function(request) {
        wesabe.failure(callback, [request]);
      }, 
      
      after: function(request) {
        if (!wesabe.isFunction(callback)) wesabe.lang.func.executeCallback(callback, 'after', [request]);
      }
    });
  });
};

wesabe.api.get = function(path, params, data, block) {
  return wesabe.api.request('GET', path, params, data, block);
};

wesabe.api.post = function(path, params, data, block) {
  return wesabe.api.request('POST', path, params, data, block);
};
