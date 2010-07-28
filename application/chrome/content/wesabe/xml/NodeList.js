wesabe.provide('xml.NodeList', function(nodes) {
  this.__nodes__ = nodes || [];
});

wesabe.lang.extend(wesabe.xml.NodeList.prototype, {
  get length() {
    return this.__nodes__.length;
  },

  item: function(index) {
    return this.__nodes__[index];
  },

  push: function(node) {
    this.__nodes__.push(node);
  }
});
