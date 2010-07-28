wesabe.provide('canvas.geometry.Rect', function(origin, size) {
  this.origin = origin;
  this.size = size;
});

wesabe.lang.extend(wesabe.canvas.geometry.Rect.prototype, {
  contains: function(point) {
    return (this.origin.x <= point.x) &&
           (this.origin.y <= point.y) &&
           (point.x <= this.origin.x + this.size.width) &&
           (point.y <= this.origin.y + this.size.height);
  },

  get width() {
    return this.size.width;
  },

  get height() {
    return this.size.height;
  },

  get left() {
    return this.origin.x;
  },

  get top() {
    return this.origin.y;
  },

  get right() {
    return this.left + this.width;
  },

  get bottom() {
    return this.top + this.height;
  },

  get center() {
    return new wesabe.canvas.geometry.Point(
      this.origin.x + this.size.width / 2,
      this.origin.y + this.size.height / 2
    );
  },
});

wesabe.canvas.geometry.Rect.make = function(x, y, w, h) {
  return new wesabe.canvas.geometry.Rect(
    new wesabe.canvas.geometry.Point(x, y),
    new wesabe.canvas.geometry.Size(w, h)
  );
};

wesabe.canvas.geometry.Rect.fromPoints = function(p1, p2) {
  var origin = new wesabe.canvas.geometry.Point(
    Math.min(p1.x, p2.x),
    Math.min(p1.y, p2.y)
  );
  var size = new wesabe.canvas.geometry.Size(
    Math.max(p1.x, p2.x) - origin.x,
    Math.max(p1.y, p2.y) - origin.y
  );

  return new wesabe.canvas.geometry.Rect(origin, size);
};

wesabe.canvas.geometry.__defineGetter__('ZeroRect', function() {
  return wesabe.canvas.geometry.Rect.make(0, 0, 0, 0);
});

wesabe.canvas.geometry.Rect.prototype.inspect = function(refs, color, tainted) {
  var s = new wesabe.util.Colorizer();
  s.disabled = !color;
  return s
    .yellow('#<')
    .bold(
      (this.constructor && this.constructor.__module__ && this.constructor.__module__.name) || 
      'Object')
    .print(' ')
    .underlined('origin')
    .yellow('=')
    .print(this.origin.inspect(refs, color, tainted))
    .print(' ')
    .underlined('size')
    .yellow('=')
    .print(this.size.inspect(refs, color, tainted))
    .yellow('>')
    .toString();
};
