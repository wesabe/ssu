wesabe.provide('canvas.geometry.Size', function(width, height) {
  this.width = width;
  this.height = height;
});

wesabe.canvas.geometry.Size.prototype.inspect = function(refs, color, tainted) {
  var s = new wesabe.util.Colorizer();
  s.disabled = !color;
  return s
    .yellow('#<')
    .bold(
      (this.constructor && this.constructor.__module__ && this.constructor.__module__.name) || 
      'Object')
    .print(' ')
    .underlined('width')
    .yellow('=')
    .print(this.width)
    .print(' ')
    .underlined('height')
    .yellow('=')
    .print(this.height)
    .yellow('>')
    .toString();
};
