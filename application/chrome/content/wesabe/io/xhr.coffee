type  = require 'lang/type'
func  = require 'lang/func'
event = require 'util/event'
{tryCatch, tryThrow} = require 'util/try'

xhr =
  urlFor: (path, params) ->
    return path unless params

    url = path
    qs = @encodeParams params
    url += (if /\?/.test(url) then '&' else '?') + qs if qs.length

    return url

  encodeParams: (params) ->
    ("#{encodeURIComponent k}=#{encodeURIComponent v}" for own k, v of params when not type.isFunction v).join '&'

  getUserAgent: ->
    try
      appInfo = Components.classes["@mozilla.org/xre/app-info;1"].getService(Components.interfaces.nsIXULRuntime)
      runtime = appInfo.OS + " " + appInfo.XPCOMABI
    catch ex
      runtime = "unknown"

    "Wesabe-ServerSideUploader/1.0 (#{runtime})"

  request: (method, path, params, data, callback) ->
    req = new XMLHttpRequest()

    before = =>
      # call `before' callback if it's given as a separate callback
      func.executeCallback callback, 'before', [req] unless type.isFunction callback
      event.trigger 'before-xhr', [req]

    after = =>
      # call `after' callback if it's given as a separate callback
      func.executeCallback callback, 'after', [req] unless type.isFunction callback
      event.trigger 'after-xhr', [req]

    tryThrow "xhr(#{method} #{path})", (log) =>
      if params and not (data or method.match(/get/i))
        data = if type.isString params
                 params
               else
                 @encodeParams params
        params = null
        contentType = "application/x-www-form-urlencoded"

      url = @urlFor path, params

      req.onreadystatechange = =>
        log.debug 'readyState=', req.readyState
        if req.readyState is 4
          log.debug 'status=',req.status
          wesabe.callback callback, req.status is 200, [req]
          after()

      req.onerror = (error) =>
        log.error error
        after()

      log.debug 'url=', url
      req.open method, url, true
      # FIXME <brian@wesabe.com>: 2008-03-11
      # <hack>
      # XULRunner 1.9b3pre and 1.9b5pre insist on tacking on ";charset=utf-8" to whatever
      # Content-type header you might set using setRequestHeader, which USAA balks at.
      # To get around this you either have to pass in a DOMDocument or an nsIInputStream,
      # so this part is only here to work around that limitation. See:
      #   https://bugzilla.mozilla.org/show_bug.cgi?id=382947
      if type.isString data
        stream = Cc['@mozilla.org/io/string-input-stream;1'].createInstance(Ci.nsIStringInputStream)
        stream.setData data, data.length
        data = stream
      # </hack>
      req.setRequestHeader "Content-Type", contentType if contentType
      req.setRequestHeader "User-Agent", @getUserAgent()
      req.setRequestHeader "Accept", "*/*, text/html"
      before()
      req.send data
      return req

  get: (path, params, block) ->
    @request 'GET', path, params, null, block

  post: (path, params, data, block) ->
    @request 'POST', path, params, data, block

  put: (path, params, data, block) ->
    @request 'PUT', path, params, data, block


module.exports = xhr
