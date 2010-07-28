wesabe.provide('ofx.Parser', function() {});
wesabe.require('xml.Parser');
wesabe.require('util.Parser');

wesabe.lang.extend(wesabe.ofx.Parser.prototype, {
  parse: function(ofx) {
    var hparser = this.parser = new wesabe.util.Parser();

    wesabe.util.event.forward(hparser, this);

    var noop = function() {};
    var quit = function() { return false };

    var work = {
      headers: [],
      get header() { return work.headers[work.headers.length-1] }
    };

    var header = {
      // first character
      start: function(p) {
        work.headers.push({name: '', value: ''});
        header.name(p);
      },

      // subsequent characters
      name: function(p) {
        work.header.name += p;
        hparser.tokens = { '[a-zA-Z0-9]': header.name, ':': header.prevalue };
      },

      // :
      prevalue: function() {
        hparser.tokens = { '[^\\r\\n]': header.value, '[\\r\\n]': header.end };
      },

      // characters in value
      value: function(p) {
        work.header.value += p;
      },

      // newline
      end: function() {
        hparser.tokens = { '\\s': noop, '[a-zA-Z]': header.start, '<': quit };
      }
    };

    hparser.tokens = { '[a-zA-Z]': header.start, '\\s': noop, '<': quit };
    hparser.parse(ofx);
    delete this.parser;
    this.offset = hparser.offset-1;

    return work.headers;
  },

  stop: function() {
    if (this.parser) this.parser.stop();
  },
});
