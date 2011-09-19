prefs = require 'util/prefs'
type  = require 'lang/type'

module.exports =
  toString: ->
    navigator.userAgent

  #
  # Set the User Agent string.
  #
  # @param [String,Object] ua
  #   Either a user agent string (e.g. "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0)")
  #   or an object containing all or part of the user agent string you wish to set. Example:
  #
  #     {appname: "Mozilla Firefox", appversion: "3.1"}
  #
  set: (ua) ->
    ua = {useragent: ua} if type.isString ua

    prefs.set "general.appname.override", ua.appname if ua.appname
    prefs.set "general.appversion.override", ua.appversion if ua.appversion
    prefs.set "general.platform.override", ua.platform if ua.platform
    prefs.set "general.useragent.override", ua.useragent if ua.useragent
    prefs.set "general.useragent.vendor", ua.vendor if ua.vendor
    prefs.set "general.useragent.vendorSub", ua.vendorSub if ua.vendorSub

    logger.info "User Agent changed to ", @toString()

  #
  # Set the User Agent string by an alias.
  #
  # @param [String] alias
  #   Shorthand for a browser, such as "IE7" or "Firefox". Tries to be fairly liberal
  #   in interpreting the alias, and it'll warn you if it can't figure it out.
  #
  setByNamedAlias: (alias) ->
    userAgent = @getByNamedAlias alias

    if userAgent
      @set userAgent
    else
      logger.warn "Unrecognized User Agent alias: ", alias

  #
  # Get the User Agent data by an alias.
  #
  getByNamedAlias: (alias) ->
    if /^((ms)?ie|internet explorer)\s*(7[\.\d]*)?$/i.test(alias)
      appname: "Microsoft Internet Explorer",
      appversion: "4.0 (compatible; MSIE 7.0; Windows NT 6.0)",
      platform: "Win32",
      useragent: "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0)",
      vendor: "",
      vendorSub: "",
    else if /^((mozilla )?firefox|ff)\s*(3[\.\d]*)?$/i.test(alias)
      appname: "Netscape",
      appversion: "5.0 (Macintosh; en-US)",
      platform: "MacIntel",
      useragent: "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.0.4) Gecko/2008102920 Firefox/3.0.4",
      vendor: "",
      vendorSub: "",
    else if /^(safari)\s*(5[\.\d]*)?$/i.test(alias)
      appname: "Netscape",
      appversion: "5.0 (Macintosh; Intel Mac OS X 10_7) AppleWebKit/534.48.3 (KHTML, like Gecko) Version/5.1 Safari/534.48.3",
      platform: "MacIntel",
      useragent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7) AppleWebKit/534.48.3 (KHTML, like Gecko) Version/5.1 Safari/534.48.3",
      vendor: "Apple Computer, Inc.",
      vendorSub: "",

  #
  # Resets the User Agent string to the default value.
  #
  revertToDefault: ->
    prefs.clear "general.appname.override"
    prefs.clear "general.appversion.override"
    prefs.clear "general.platform.override"
    prefs.clear "general.useragent.override"
    prefs.clear "general.useragent.vendor"
    prefs.clear "general.useragent.vendorSub"
    logger.info "Reverted User Agent to the default value: ", navigator.userAgent
