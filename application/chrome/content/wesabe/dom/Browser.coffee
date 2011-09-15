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
    uri = @joinURI(browser, uri)
    wesabe.debug('Loading uri=', uri)
    browser.loadURI(wesabe.untaint(uri), null, null)

  #
  # Get the absolute uri by joining +uri+ to the current uri of +browser+.
  # +uri+ may be either relative or absolute.
  #
  joinURI: (browser, uri) ->
    tainted = wesabe.isTainted(uri)
    uri = wesabe.untaint(uri) if tainted
    uri = browser.currentURI?.resolve(uri)

    if tainted then wesabe.taint(uri) else uri

  #
  # Get the current uri of +browser+ as a string.
  #
  getURI: (browser) ->
    wesabe.taint(browser.currentURI?.resolve(null))

  #
  # Determines whether +browser+ is currently at +uri+,
  # which may be relative or absolute.
  #
  atURI: (browser, uri) ->
    currentURI = browser.currentURI
    return true if currentURI is null and uri is null

    wesabe.untaint(@getURI(browser)) == wesabe.untaint(@joinURI(browser, uri))
