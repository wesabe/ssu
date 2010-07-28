wesabe.provide('xml.CloseTag', function(name) {
  this.name = name || '';
});

wesabe.lang.extend(wesabe.xml.CloseTag.prototype, {
  beginParsing: function(parser) {
    this.trigger('start-close-tag', parser);
  },

  doneParsing: function(parser) {
    this.parsed = true;
    this.trigger('end-close-tag close-tag node', parser);
  },

  trigger: function(events, parser) {
    parser.trigger(events, [this]);
  },

  toElement: function() {
    return new wesabe.xml.Element(this.name);
  },
});
