wesabe.provide('util.Timer');

/**
 * Measure the time taken to perform actions given by a label. Example:
 *
 *   var timer = new wesabe.util.Timer();
 *   timer.start('Compute');
 *   // do some computing
 *   timer.end('Compute');
 *
 * You can also pass along a callback which will call `end' for you:
 *
 *   timer.start('Compute', function() {
 *     // do some computing
 *   });
 *
 * Calling start/end multiple times with the same label is allowed.
 * When you call `summarize' they will simply be added together:
 *
 *   while (something) {
 *     // `start' called with 'Compute' several times
 *     timer.start('Compute', function() {
 *       // do some computing
 *     });
 *   }
 *
 *   // adds up all the 'Compute' durations
 *   timer.summarize();  // => {Compute: 12984}
 */
wesabe.util.Timer = function() {
  this.data = {};
  this.pending = [];
};

wesabe.util.Timer.prototype.__defineGetter__('now', function() {
  return new Date().getTime();
});

wesabe.util.Timer.prototype.start = function(label, fn) {
  var d = this.data, pending = this.pending;
  if (!d[label]) d[label] = [];
  d[label].push({start: this.now});
  var index = d[label].length - 1;

  while (pending.length) {
    var datum = pending.shift();
    this.end(datum.label, datum.index);
  }

  if (wesabe.isFunction(fn)) {
    var retval = fn();
    this.end(label, index);
    return retval;
  } else if (fn && wesabe.isFalse(fn.overlap)) {
    pending.push({label: label, index: index});
  }

  return index;
};

wesabe.util.Timer.prototype.end = function(label, index) {
  if (!this.data[label]) {
    wesabe.warn("No timer entry found for ", label);
  } else {
    if (wesabe.isNumber(index)) {
      if (this.data[label][index]) {
        this.data[label][index].end = this.now;
      } else {
        wesabe.warn("No timer entry found for ", label, " at index ", index);
      }
    } else {
      for (var i = 0; i < this.data[label].length; i++) {
        // assume that the earliest one without an end is the one they want
        if (!this.data[label][i].end) {
          this.data[label][i].end = this.now;
          return;
        }
      }

      wesabe.warn("No unfinished timer entry found for ", label);
    }
  }
};

wesabe.util.Timer.prototype.summarize = function() {
  var summary = {}, d = this.data, now = this.now;
  for (var label in d) {
    var total = 0;
    d[label].forEach(function(range){ total += (range.end || now) - range.start });
    summary[label] = total;
  }
  return summary;
};
