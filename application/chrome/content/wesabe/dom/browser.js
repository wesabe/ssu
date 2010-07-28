wesabe.provide('dom.browser');

wesabe.require('lang.*');
wesabe.require('util.*');

wesabe.dom.browser = {
  /**
   * Navigate to the given uri.
   * @method go
   * @param browser {XULBrowser} A <browser/> element.
   * @param uri {String} An absolute or relative uri pointing to a web site.
   *
   *   browser.go('https://wesabe.com/')
   *   browser.go('/groups')
   */
  go: function(browser, uri) {
    var curi = browser.currentURI,
        tainted = wesabe.isTainted(uri);
    if (tainted) uri = wesabe.untaint(uri);
    if (curi) {
      uri = curi.resolve(uri);
    }
    wesabe.debug('Loading uri=', tainted ? wesabe.taint(uri.toString()) : uri.toString());
    browser.loadURI(uri, null, null);
  },

  /**
   * Get the current location of this browser, null if it is not on a page.
   *
   * @param browser {XULBrowser} A <browser/> element.
   * @return {String, null} The location of the browser.
   */
  getURI: function(browser) {
    var uri = browser.currentURI;
    return uri && uri.toString();
  },
};
