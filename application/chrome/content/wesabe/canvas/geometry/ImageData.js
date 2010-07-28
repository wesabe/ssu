wesabe.provide('canvas.geometry.ImageData', function(rect, data) {
  this.rect = rect;
  this.data = data;
});

wesabe.require('crypto');

wesabe.lang.extend(wesabe.canvas.geometry.ImageData.prototype, {
  getDataAtPoint: function(point) {
    if (!this.rect.contains(point)) {
      throw new Error("Cannot get image data for out-of-bounds point (point="+wesabe.util.inspect(point)+", rect="+wesabe.util.inspect(this.rect)+")");
    }

    var offset = (point.x + this.rect.size.width * point.y) * 4;
    return this.data.slice(offset, offset + 4);
  },

  withRect: function(rect) {
    var data = [];

    for (var y = rect.top; y < rect.bottom; y++) {
      for (var x = rect.left; x < rect.right; x++) {
        data = data.concat(this.getDataAtPoint(new wesabe.canvas.geometry.Point(x, y)));
      }
    }

    return new wesabe.canvas.geometry.ImageData(rect, data);
  },

  get signature() {
    return wesabe.crypto.md5(this.data);
  },

  findPoint: function(options) {
    var p = options.start, bounds = options.bounds || this.rect;

    while (bounds.contains(p)) {
      if (options.color) {
        if (this.pointHasColor(p, options.color)) {
          return p;
        }
      } else if (wesabe.isFunction(options.test)) {
        if (options.test(p)) {
          return p;
        }
      }

      // move p according to the step option
      p = new wesabe.canvas.geometry.Point(p.x + options.step.width, p.y + options.step.height);
    }

    return null;
  },

  pointHasColor: function(p, color) {
    return wesabe.lang.array.equal(this.getDataAtPoint(p), color);
  },

  findPoints: function(options) {
    var bounds = options.bounds || this.rect,
        points = [],
        p0     = bounds.origin.withOffset(bounds.size), // bottom-right
        p      = new wesabe.canvas.geometry.Point(p0.x, p0.y);

    do {
      do {
        if (options.test(p)) points.push(p.clone());
      } while (--p.x >= bounds.left)
      p.x = p0.x;
    } while (--p.y >= bounds.top)

    return points;
  },
});
