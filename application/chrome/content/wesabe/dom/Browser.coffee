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
