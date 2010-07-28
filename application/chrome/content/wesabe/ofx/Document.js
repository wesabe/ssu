wesabe.provide('ofx.Document', function(ofx, verboten) {
  if (ofx) this.parse(ofx, verboten);
});
wesabe.require('ofx.Parser');

// inherit from wesabe.xml.Document
wesabe.lang.extend(wesabe.ofx.Document.prototype, wesabe.xml.Document.prototype);

wesabe.lang.extend(wesabe.ofx.Document.prototype, {
  /**
   * Parse an OFX document, including headers.
   */
  parse: function(ofx, verboten) {
    var parser = new wesabe.ofx.Parser();
    var xml = new wesabe.xml.Document();
    var self = this;

    wesabe.tryThrow('ofx.Document#parse', function(log) {
      self.headers = parser.parse(ofx);
      xml.parse(ofx.slice(parser.offset), verboten);
      wesabe.lang.extend(self, xml);
    });

    return this;
  },
});
