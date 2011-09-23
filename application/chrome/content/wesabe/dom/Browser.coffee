type = require 'lang/type'
Page = require 'dom/Page'

class Browser
  constructor: (@browser) ->
    unless @browser
      @browser = document.createElement 'browser'
      document.documentElement.appendChild @browser

  @::__defineGetter__ 'mainPage', ->
    Page.wrap @browser.contentDocument

  #
  # Get the current uri of browser as a string.
  #
  @::__defineGetter__ 'url', ->
    wesabe.taint @browser.currentURI?.resolve(null)

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
    @browser.loadURI wesabe.untaint(uri), null, null

  #
  # Get the absolute uri by joining +uri+ to the current uri of +browser+.
  # +uri+ may be either relative or absolute.
  #
  joinURI: (uri) ->
    uri = wesabe.untaint uri
    uri = @browser.currentURI?.resolve uri

    wesabe.taint uri

  #
  # Determines whether browser is currently at +uri+,
  # which may be relative or absolute.
  #
  atURI: (uri) ->
    currentURI = @browser.currentURI
    return true if currentURI is null and uri is null

    wesabe.untaint(@url) is wesabe.untaint(@joinURI uri)

  @wrap: (browser) ->
    if type.is browser, @
      browser
    else
      new @ browser


module.exports = Browser
