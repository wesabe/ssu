wesabe.provide('util.url')

class URL
  constructor: (@scheme, @host, @port, @pathname, @search) ->

  this::__defineGetter__ 'protocol', ->
    "#{@scheme}:"

  this::__defineSetter__ 'protocol', (protocol) ->
    @scheme = protocol.match(/^(.*?):?$/)[1]

  this::__defineGetter__ 'hostAndPort', ->
    "#{@host}#{if @port then ':'+port else ''}"

  toString: ->
    "#{@protocol}//#{@hostAndPort}#{@pathname}#{@search||''}"

#
# Provides utility methods for manipulating urls, mainly joining them together.
#
wesabe.util.url =
  #
  # Joins two or more urls and/or fragments together. Note that the first one 
  # MUST be an absolute url, and the rest may be absolute or relative.
  # Simple example:
  #
  #   >> wesabe.util.url.join('https://www.wesabe.com/', 'accounts');
  #   => "https://www.wesabe.com/accounts"
  #
  # An example of tacking on an absolute path:
  #
  #   >> wesabe.util.url.join('http://go.com/abc', '/foobar');
  #   => "http://go.com/foobar"
  #
  # An example of replacing a whole url:
  #
  #   >> wesabe.util.url.join('http://mint.com/', 'https://wesabe.com/', 'user/login');
  #   => "https://wesabe.com/user/login"
  #
  join: (parts...) ->
    url = ''

    for part in parts
      if @isAbsoluteUrl(part)
        url = part
      else
        # part is relative
        if @isAbsoluteUrl(url)
          # url is absolute, so tack part onto url
          url = @parts(url)
          if @isAbsolutePath(part)
            # part looks like "/foo/bar"
            url.pathname = part
          else
            # part looks like "foo/bar"
            url.pathname += '/' unless /\/$/.test(url.pathname)
            url.pathname += part

          url.search = null
        else
          # url is relative too, uh oh
          throw new Error("Failed to join url parts #{url} and #{part} because they're both relative")

      url = url.toString()

    return url

  isAbsoluteUrl: (url) ->
    /^([a-z]+):\/\//.test(url)

  isAbsolutePath: (path) ->
    /^\//.test(path)

  parts: (url) ->
    p = url.match(/^([a-z]+):\/\/([^\/:]*)(?::(\d+))?([^\?]+)(\?.*)?/)
    new URL(p[1], p[2], p[3], p[4], p[5])
