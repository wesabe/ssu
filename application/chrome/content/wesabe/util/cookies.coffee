wesabe.provide('util.cookies')
wesabe.require('lang.json')

cookieManager = ->
  Components.classes["@mozilla.org/cookiemanager;1"]
    .getService(Components.interfaces.nsICookieManager2)

wesabe.util.cookies =
  dump: ->
    dump = []
    cookies = cookieManager().enumerator

    while cookies.hasMoreElements()
      cookie = cookies.getNext()
      cookie = cookie.QueryInterface(Components.interfaces.nsICookie)

      dump.push
        host: cookie.host
        path: cookie.path
        name: cookie.name
        value: cookie.value
        isSecure: cookie.isSecure
        expires: cookie.expires

    return wesabe.lang.json.render(dump)

  restore: (cookies) ->
    if wesabe.isString(cookies)
      cookies = wesabe.lang.json.parse(cookies)

    manager = cookieManager()
    for cookie in cookies
      manager.add(
        cookie.host,      # domain
        cookie.path,      # path
        cookie.name,      # name
        cookie.value,     # value
        cookie.isSecure,  # isSecure
        true,             # isHttpOnly
        false,            # isSession
        cookie.expires)   # expiry
