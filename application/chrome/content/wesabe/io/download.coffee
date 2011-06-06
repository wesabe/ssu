wesabe.provide 'io.download', (url, file, callback) ->
  Cc = Components.classes
  Ci = Components.interfaces

  downloader = Cc["@mozilla.org/network/downloader;1"].createInstance()
  ioService = Cc["@mozilla.org/network/io-service;1"].getService(Ci.nsIIOService)
  file = wesabe.io.file.open(file) if file and not file.path?

  delegate = onDownloadComplete: (dl, req, ctxt, status, file) ->
               try
                 match = httpChannel.getResponseHeader('Content-Disposition').match(/filename="([^"]+)"/i)
                 suggestedFilename = match?[1]
               catch err
                 match = url.match(/.+\/([^\/\?]+)/)
                 suggestedFilename = match?[1]

               wesabe.callback(callback, req.status is 0, [file, suggestedFilename])

  downloader.QueryInterface(Ci.nsIDownloader)
  downloader.init(delegate, file)

  httpChannel = ioService.newChannel(url, '', null)
  httpChannel.QueryInterface(Ci.nsIHttpChannel)
  httpChannel.asyncOpen(downloader, null)

  return downloader
