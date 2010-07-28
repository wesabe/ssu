wesabe.provide('util.url');

/**
 * Provides utility methods for manipulating urls, mainly joining them together.
 */
wesabe.util.url = {
  /**
   * Joins two or more urls and/or fragments together. Note that the first one 
   * MUST be an absolute url, and the rest may be absolute or relative.
   * Simple example:
   *   
   *   >> wesabe.util.url.join('https://www.wesabe.com/', 'accounts');
   *   => "https://www.wesabe.com/accounts"
   *   
   * An example of tacking on an absolute path:
   *   
   *   >> wesabe.util.url.join('http://go.com/abc', '/foobar');
   *   => "http://go.com/foobar"
   *   
   * An example of replacing a whole url:
   *   
   *   >> wesabe.util.url.join('http://mint.com/', 'https://wesabe.com/', 'user/login');
   *   => "https://wesabe.com/user/login"
   */
  join: function() {
    var url = '';
    
    wesabe.lang.array.from(arguments).forEach(function(part) {
      if (wesabe.util.url.isAbsoluteUrl(part)) {
        url = part;
      } else {
        // part is relative
        if (wesabe.util.url.isAbsoluteUrl(url)) {
          // url is absolute, so tack part onto url
          url = wesabe.util.url.parts(url);
          if (wesabe.util.url.isAbsolutePath(part)) {
            // part looks like "/foo/bar"
            url.pathname = part;
          } else {
            // part looks like "foo/bar"
            if (!/\/$/.test(url.pathname)) url.pathname += '/';
            url.pathname += part;
          }
          url.search = null;
        } else {
          // url is relative too, uh oh
          throw new Error("Failed to join url parts " + url + " and " + part + " because they're both relative");
        }
      }
      url = url.toString()
    });
    
    return url;
  }, 
  
  isAbsoluteUrl: function(url) {
    return /^([a-z]+):\/\//.test(url);
  }, 
  
  isAbsolutePath: function(path) {
    return /^\//.test(path);
  }, 
  
  parts: function(url) {
    var p = url.match(/^([a-z]+):\/\/([^\/:]*)(?::(\d+))?([^\?]+)(\?.*)?/);
    return {
      scheme: p[1], 
      get protocol() { return this.scheme+':' }, 
      set protocol(p) { this.scheme = p.match(/^(.*?):?$/)[1] }, 
      host: p[2], 
      port: p[3], 
      get hostAndPort() { return this.host+(this.port ? ':'+this.port : '') }, 
      pathname: p[4], 
      search: p[5], 
      toString: function() {
        return this.protocol+'//'+
               this.hostAndPort+
               this.pathname+
               (this.search||'');
      }
    };
  }
};
