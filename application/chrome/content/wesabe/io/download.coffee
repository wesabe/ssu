wesabe.provide 'io.download', (url, file, callback) ->
  Cc = Components.classes
  Ci = Components.interfaces

  downloader = Cc["@mozilla.org/network/downloader;1"].createInstance()
  ioService = Cc["@mozilla.org/network/io-service;1"].getService(Ci.nsIIOService)
  file = wesabe.io.file.open(file) unless file.path?

  delegate = onDownloadComplete: (dl, req, ctxt, status, file) ->
               wesabe.callback(callback, req.status is 0, [file])

  downloader.QueryInterface(Ci.nsIDownloader)
  downloader.init(delegate, file)

  httpChannel = ioService.newChannel(url, '', null)
  httpChannel.QueryInterface(Ci.nsIHttpChannel)
  httpChannel.asyncOpen(downloader, null)
