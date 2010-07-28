wesabe.provide('util.Parser');

wesabe.util.Parser = function() {};

wesabe.util.Parser.prototype.__defineSetter__('tokens', function(tokens) {
  var toks = [];
  for (var tok in tokens) {
    toks.push({pattern: new RegExp('^'+tok+'$'), callback: tokens[tok]});
  }
  this.__tokens__ = toks;
});

wesabe.util.Parser.prototype.parse = function(what) {
  this.parsing = what;
  this.offset = 0;
  
  var eof = true;
  
  while (!this.hasStopRequest && this.offset < what.length) {
    if (!this.process(what[this.offset])) {
      eof = false;
      break;
    }
  }
  
  if (eof && !this.hasStopRequest) this.process('EOF');
  delete this.parsing;
};

wesabe.util.Parser.prototype.stop = function() {
  this.hasStopRequest = true;
};

wesabe.util.Parser.prototype.process = function(p) {
  var patterns = [];
  
  for (var i = 0; i < this.__tokens__.length; i++) {
    var tok = this.__tokens__[i];
    patterns.push(tok.pattern);
    if (tok.pattern.test(p)) {
      var retval;
      
      if (wesabe.isFunction(tok.callback)) {
        // call the provided callback function
        retval = tok.callback(p);
      } else {
        throw new Error('Unknown callback type ', tok.callback, ', please pass a Function or a Parser');
      }
      this.offset++;
      return retval !== false;
    }
  }
  
  throw new Error('Unexpected '+p+' (offset='+this.offset+', before='+
                  wesabe.util.inspect(this.parsing.slice(this.offset-15, this.offset))+
                  ', after='+
                  wesabe.util.inspect(this.parsing.slice(this.offset, this.offset+15))+
                  ', together='+
                  wesabe.util.inspect(this.parsing.slice(this.offset-15, this.offset+15))+
                  ') while looking for one of '+wesabe.util.inspect(patterns));
};

wesabe.util.Parser.prototype.trigger = function(events, args) {
  wesabe.trigger(this, events, args);
};
