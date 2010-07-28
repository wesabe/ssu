wesabe.provide('xml.Text', function(text) {
  this.text = text || '';
});

wesabe.lang.extend(wesabe.xml.Text.prototype, {
  beginParsing: function(parser) {
    this.trigger('start-text', parser);
  },

  doneParsing: function(parser) {
    this.parsed = true;
    this.trigger('end-text text node', parser);
  },

  trigger: function(events, parser) {
    parser.trigger(events, [this]);
  },

  inspect: function(refs, color, tainted) {
    var s = new wesabe.util.Colorizer();
    s.disabled = !color;

    return s
      .reset()
      .print(wesabe.util._inspectString(this.text, color, tainted))
      .reset()
      .toString();
  },
});
