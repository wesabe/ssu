type    = require 'lang/type'
Page    = require 'dom/Page'
privacy = require 'util/privacy'

class Browser
  constructor: (@browser) ->
    unless @browser
      @browser = document.createElement 'browser'
      @browser.setAttribute 'type', 'content-targetable'
      @browser.setAttribute 'flex', '1'
      document.documentElement.appendChild @browser

  @::__defineGetter__ 'mainPage', ->
    Page.wrap @browser.contentDocument

  #
  # Get the current uri of browser as a string.
  #
  @::__defineGetter__ 'url', ->
    privacy.taint @browser.currentURI?.resolve(null)

  #
  # Proxy addEventListener through so that event.add will work.
  #
  addEventListener: (args...) ->
    @browser.addEventListener args...

  #
  # Remove this browser from the container DOM.
  #
  remove: ->
    @browser.parentNode.removeChild @browser

  #
  # Navigate to the given uri.
  # @method go
  # @param uri {String} An absolute or relative uri pointing to a web site.
  #
  #   browser.go('http://www.google.com/')
  #   browser.go('/groups')
  #
  go: (uri) ->
    # if the browser is newly-attached to its parent (and doesn't have a currentURI property),
    # then we let this cycle of the run loop complete before we try again
    return (setTimeout => @go uri, 0) if @browser.currentURI is null

    uri = @joinURI uri
    logger.debug 'Loading uri=', uri
    @browser.loadURI privacy.untaint(uri), null, null

  #
  # Get the absolute uri by joining +uri+ to the current uri of +browser+.
  # +uri+ may be either relative or absolute.
  #
  joinURI: (uri) ->
    uri = privacy.untaint uri
    uri = @browser.currentURI?.resolve uri

    privacy.taint uri

  #
  # Determines whether browser is currently at +uri+,
  # which may be relative or absolute.
  #
  atURI: (uri) ->
    currentURI = @browser.currentURI
    return true if currentURI is null and uri is null

    privacy.untaint(@url) is privacy.untaint(@joinURI uri)

  @wrap: (browser) ->
    if type.is browser, @
      browser
    else
      new @ browser


module.exports = Browser

# DEPRECATIONS
#
# This class used to be a set of functions that were passed a XULBrowser
# as the first argument, like so:
#
#   wesabe.dom.browser.go(browser, "http://www.google.com/"
#
# Now it's an actual class that keeps the XULBrowser as an ivar. To help
# with the transition, this section adds back wesabe.dom.browser.go and
# friends but yells at you that you're using a deprecated method.
#
deprecated =
  getURI: (browser) ->
    logger.deprecated "wesabe.dom.browser.getURI(browser)", "browser.url"
    browser.url

for name in ['go', 'joinURI', 'atURI']
  do (name) ->
    deprecated[name] = (browser, args...) ->
      logger.deprecated "wesabe.dom.browser.#{name}(browser, ...)", "browser.#{name}(...)"
      browser[name](args...)

wesabe.provide 'dom.browser', deprecated
