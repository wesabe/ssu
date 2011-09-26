file = require 'io/file'

TYPE = 'image/png'

writeToFile = (window, path) ->
  file.write path, serializeCanvas(canvasWithContentsOfWindow(window))

  return true

canvasWithContentsOfWindow = (window) ->
  document = window.document
  canvas   = document.createElement 'canvas'
  width    = window.innerWidth + window.scrollMaxX
  height   = window.innerHeight + window.scrollMaxY

  canvas.setAttribute 'width', width
  canvas.setAttribute 'height', height

  context  = canvas.getContext '2d'
  context.drawWindow window,
    0,                 #left
    0,                 #top
    width,
    height,
    'rgb(255,255,255)' #bgcolor

  return canvas

serializeCanvas = (canvas) ->
  dataurl = canvas.toDataURL TYPE
  return atob(dataurl.substring(13 + TYPE.length)) # hack off scheme


module.exports = {writeToFile}
