File = require 'io/File'

TYPE = 'image/png'

imageDataForWindow = (window) ->
  serializeCanvas canvasWithContentsOfWindow(window)

imageDataForImage = (image) ->
  serializeCanvas canvasWithImage(image)

writeToFile = (windowOrImage, path) ->
  data = if windowOrImage?.tagName?.toLowerCase() is 'img'
    imageDataForImage windowOrImage
  else
    imageDataForWindow windowOrImage

  File.write path, data

  return true

canvasWithImage = (image) ->
  document = image.ownerDocument
  canvas   = document.createElement 'canvas'
  width    = image.width
  height   = image.height

  canvas.setAttribute 'width', width
  canvas.setAttribute 'height', height

  context = canvas.getContext '2d'
  context.drawImage image, 0, 0

  return canvas


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


module.exports = {writeToFile, imageDataForWindow, imageDataForImage}
