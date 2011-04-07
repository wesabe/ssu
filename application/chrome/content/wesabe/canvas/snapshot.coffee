wesabe.provide('canvas.snapshot')
wesabe.require('io.file')

wesabe.canvas.snapshot =
  TYPE: 'image/png',

  writeToFile: (window, path) ->
    canvas = @canvasWithContentsOfWindow(window)

    data = @serializeCanvas(canvas)
    file = wesabe.io.file.open(path)

    wesabe.io.file.write(file, data)

    return true

  canvasWithContentsOfWindow: (window) ->
    document = window.document
    canvas   = document.createElement('canvas')
    width    = window.innerWidth + window.scrollMaxX
    height   = window.innerHeight + window.scrollMaxY

    canvas.setAttribute('width', width)
    canvas.setAttribute('height', height)

    context  = canvas.getContext('2d')
    context.drawWindow window,
      0,                 #left
      0,                 #top
      width,
      height,
      'rgb(255,255,255)' #bgcolor

    return canvas

  serializeCanvas: (canvas) ->
    dataurl = canvas.toDataURL(wesabe.canvas.snapshot.TYPE)
    return atob(dataurl.substring(13 + @TYPE.length)) # hack off scheme
