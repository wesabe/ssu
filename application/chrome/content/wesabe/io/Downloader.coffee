{open} = require 'io/file'

class Downloader
  constructor: (@url, @file, @callback) ->
    @_downloader = Cc["@mozilla.org/network/downloader;1"].createInstance()
    @_ioService = Cc["@mozilla.org/network/io-service;1"].getService(Ci.nsIIOService)

    @_downloader.QueryInterface Ci.nsIDownloader
    @_downloader.init this, @file

  @::__defineGetter__ 'file', ->
    @_file

  @::__defineSetter__ 'file', (file) ->
    if file.path?
      @_file = file
    else
      @_file = open file

  #
  # Starts the download. This is the only public method for this class.
  #
  download: ->
    @_httpChannel = @_ioService.newChannel @url, '', null
    @_httpChannel.QueryInterface Ci.nsIHttpChannel
    @_httpChannel.asyncOpen @_downloader, null

  @download: (url, file, callback) ->
    (new Downloader url, file, callback).download()

  #
  # nsIDownloader delegate callback function.
  #
  onDownloadComplete: (dl, req, ctxt, status, file) ->
     try
       match = @_httpChannel.getResponseHeader('Content-Disposition').match(/filename="([^"]+)"/i)
       suggestedFilename = match?[1]
     catch err
       match = @url.match(/.+\/([^\/\?]+)/)
       suggestedFilename = match?[1]

      try
        contentType = @_httpChannel.getResponseHeader('Content-Type')
      catch err
        contentType = undefined

     wesabe.callback @callback, req.status is 0, [file, suggestedFilename, contentType]

     delete @_httpChannel
     delete @_downloader
     delete @_ioService
     delete @callback


module.exports = Downloader
