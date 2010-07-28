wesabe.provide('canvas.snapshot');
wesabe.require('io.file');

wesabe.canvas.snapshot = {
  TYPE: 'image/png', 
  
  writeToFile: function(window, path) {
    var canvas = wesabe.canvas.snapshot.canvasWithContentsOfWindow(window);
    
    var data = wesabe.canvas.snapshot.serializeCanvas(canvas);
    var file = wesabe.io.file.open(path);
    
    wesabe.io.file.write(file, data);
    
    return true;
  }, 
  
  canvasWithContentsOfWindow: function(window) {
    var document = window.document;
    var canvas   = document.createElement('canvas');
    var width    = window.innerWidth + window.scrollMaxX;
    var height   = window.innerHeight + window.scrollMaxY;
    
    canvas.setAttribute('width', width);
    canvas.setAttribute('height', height);
    
    var context  = canvas.getContext('2d');
    context.drawWindow(window, /*left*/0, /*top*/0, width, height, /*bgcolor*/'rgb(255,255,255)');
    
    return canvas;
  }, 
  
  serializeCanvas: function(canvas) {
    var dataurl = canvas.toDataURL(wesabe.canvas.snapshot.TYPE);
    return atob(dataurl.substring(13 + wesabe.canvas.snapshot.TYPE.length)); // hack off scheme
  }
};
