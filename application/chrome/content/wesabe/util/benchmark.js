wesabe.provide('util.benchmark');

wesabe.util.benchmark = {
  bm: function(callbacks, count) {
    // wesabe.info('Benchmark');
    wesabe.info('================================================');
    for (var key in callbacks) {
      wesabe.info(key,': ',wesabe.util.benchmark.time(callbacks[key], count));
    }
    wesabe.info('================================================');
  }, 
  
  time: function(callback, count) {
    if (wesabe.isUndefined(count)) count = 1;
    var times = [], total = 0, sqtotal = 0, average, variance, stddev;
    
    
    for (var i = 0; i < count; i++) {
      try {
        var now = new Date().getTime(), diff;
        callback.call(wesabe);
        diff = new Date().getTime() - now;
        
        total += diff;
        sqtotal += Math.pow(diff, 2);
        times.push(diff);
      } catch (e) {
        return {inspect: function(){ "error: "+e.toString() }};
      }
    }
    
    average  = parseFloat(total) / count;
    variance = (parseFloat(sqtotal) / count) - Math.pow(average, 2);
    stddev   = Math.pow(variance, 0.5);
    
    return {
      average: average, 
      variance: variance, 
      stddev: stddev, 
      total: total, 
      count: count, 
      round: function(f) {
        return parseFloat(parseInt(parseFloat(f)*100))/100;
      }, 
      inspect: function() {
        return "average: "+this.round(this.average,2)+"ms"+
              "  stddev: "+this.round(this.stddev)+"ms"+
               "  total: "+this.round(this.total)+"ms"+
               "  ("+this.count+" times)";
      }
    }
  }
};

wesabe.bm = wesabe.util.benchmark.bm;
