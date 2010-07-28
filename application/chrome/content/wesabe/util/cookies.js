wesabe.provide('util.cookies');
wesabe.require('lang.json');

wesabe.util.cookies = {
  get manager() {
    return Components.classes["@mozilla.org/cookiemanager;1"]
      .getService(Components.interfaces.nsICookieManager2);
  }, 
  
  dump: function() {
    var dump = [];
    var cookies = wesabe.util.cookies.manager.enumerator, cookie;
    while (cookies.hasMoreElements()) {
      cookie = cookies.getNext();
      cookie = cookie.QueryInterface(Components.interfaces.nsICookie);
      dump.push({
        host: cookie.host, 
        path: cookie.path, 
        name: cookie.name, 
       value: cookie.value, 
    isSecure: cookie.isSecure, 
     expires: cookie.expires });
    }
    return wesabe.lang.json.render(dump);
  }, 
  
  restore: function(cookies) {
    if (wesabe.isString(cookies))
      cookies = wesabe.lang.json.parse(cookies);
    
    var manager = wesabe.util.cookies.manager;
    cookies.forEach(function(cookie) {
      manager.add(
        /* domain */      cookie.host, 
        /* path */        cookie.path, 
        /* name */        cookie.name, 
        /* value */       cookie.value, 
        /* isSecure */    cookie.isSecure, 
        /* isHttpOnly */  true, 
        /* isSession */   false, 
        /* expiry */      cookie.expires);
    });
  }
};
