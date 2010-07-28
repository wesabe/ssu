wesabe.provide('xml.Attribute', function(name, value) {
  this.name = name || '';
  this.value = value || '';
});

wesabe.lang.extend(wesabe.xml.Attribute.prototype, {
  beginParsing: function(parser) {
    this.trigger('start-attribute', parser);
  },

  doneParsing: function(parser) {
    this.parsed = true;
    this.trigger('end-attribute attribute', parser);
  },

  trigger: function(events, parser) {
    parser.trigger(events, [this]);
  },

  get nodeName() {
    return this.name;
  },

  get nodeValue() {
    return this.value;
  },
});
