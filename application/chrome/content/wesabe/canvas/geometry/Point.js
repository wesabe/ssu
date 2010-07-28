wesabe.provide('canvas.geometry.Point', function(x, y) {
  this.x = x;
  this.y = y;
});

wesabe.lang.extend(wesabe.canvas.geometry, {
  get ZeroPoint() {
    return new wesabe.canvas.geometry.Point(0, 0);
  },
});

wesabe.lang.extend(wesabe.canvas.geometry.Point.prototype, {
  get nearestPixel() {
    return new wesabe.canvas.geometry.Point(
      Math.round(this.x),
      Math.round(this.y)
    );
  },

  withOffset: function(x, y) {
    if (y === undefined) {
      y = x.y || x.height;
      x = x.x || x.width;
    }

    return new wesabe.canvas.geometry.Point(
      this.x + x,
      this.y + y
    );
  },

  clone: function() {
    return new wesabe.canvas.geometry.Point(this.x, this.y);
  },
});

wesabe.canvas.geometry.Point.prototype.inspect = function(refs, color, tainted) {
  var s = new wesabe.util.Colorizer();
  s.disabled = !color;
  return s
    .yellow('#<')
    .bold(
      (this.constructor && this.constructor.__module__ && this.constructor.__module__.name) || 
      'Object')
    .print(' ')
    .underlined('x')
    .yellow('=')
    .print(this.x)
    .print(' ')
    .underlined('y')
    .yellow('=')
    .print(this.y)
    .yellow('>')
    .toString();
};
