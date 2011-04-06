wesabe.provide('dom.browser')

wesabe.require('lang.*')
wesabe.require('util.*')

wesabe.dom.browser =
  #
  # Navigate to the given uri.
  # @method go
  # @param browser {XULBrowser} A <browser/> element.
  # @param uri {String} An absolute or relative uri pointing to a web site.
  #
  #   browser.go('https://wesabe.com/')
  #   browser.go('/groups')
  #
  go: (browser, uri) ->
    curi = browser.currentURI
    tainted = wesabe.isTainted(uri)
    uri = wesabe.untaint(uri) if tainted
    uri = curi.resolve(uri) if curi
    wesabe.debug('Loading uri=', (if tainted then wesabe.taint(uri.toString()) else uri.toString()))
    browser.loadURI(uri, null, null)

  #
  # Get the current location of this browser, null if it is not on a page.
  #
  # @param browser {XULBrowser} A <browser/> element.
  # @return {String, null} The location of the browser.
  #
  getURI: (browser) ->
    browser.currentURI?.toString()
