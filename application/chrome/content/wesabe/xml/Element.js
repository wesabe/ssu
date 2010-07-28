wesabe.provide('xml.Element', function(name, selfclosing) {
  this.name = name;
  if (selfclosing) this.selfclosing = true;
  this.__children__ = [];
  this.__attributes__ = {};
});

wesabe.require('dom.Selector');

wesabe.lang.extend(wesabe.xml.Element.prototype, {
  //
  // DOM-ish methods
  //

  /* attribute stuff */

  get id() {
    return this.__attributes__.id || null;
  },

  get className() {
    return this.__attributes__['class'] || '';
  },

  get childNodes() {
    return new wesabe.xml.NodeList(this.__children__);
  },

  get tagName() {
    return this.name;
  },

  setAttribute: function(name, value) {
    this.__attributes__[name] = value;
  },

  get attributes() {
    var attributes = [];

    for (var name in this.__attributes__)
      attributes.push(new wesabe.xml.Attribute(name, this.__attributes__[name]));

    return attributes;
  },

  /* child stuff */

  appendChild: function(node) {
    this.__children__.push(node);
    node.parentNode = this;
  },

  get firstChild() {
    return this.__children__[0];
  },

  get lastChild() {
    return this.__children__[this.__children__.length-1];
  },

  get text() {
    return this.__children__.map(function(n){ return n.text }).join('');
  },

  insertBefore: function(node, adjacentNode) {
    for (var i = 0; i < this.__children__.length; i++) {
      if (this.__children__[i] == adjacentNode) {
        this.__children__.splice(i, 0, node);
        node.parentNode = this;
        return node;
      }
    }
    throw new Error("Element#insertBefore: Could not find adjacentNode "+wesabe.util.inspect(adjacentNode));
  },

  insertAfter: function(node, adjacentNode) {
    for (var i = 0; i < this.__children__.length; i++) {
      if (this.__children__[i] == adjacentNode) {
        this.__children__.splice(i+1, 0, node);
        node.parentNode = this;
        return node;
      }
    }
    throw new Error("Element#insertAfter: Could not find adjacentNode "+wesabe.util.inspect(adjacentNode));
  },

  /* finders */

  search: function(callback, one) {
    var found = [];
    var descendants = [this]

    while (descendants.length) {
      var child = descendants.shift();
      if (callback(child)) {
        if (one) return child;
        else found.push(child);
      }
      if (wesabe.isArray(child.__children__)) {
        descendants = descendants.concat(child.__children__);
      }
    }

    if (!one) return found;
  },

  getElementById: function(id) {
    return this.search(function(node) {
      return node.id == id;
    }, true);
  },

  getElementsByTagName: function(name) {
    return this.search(function(node) {
      return node.nodeType == 1 && (name == '*' || node.name.toLowerCase() == name.toLowerCase());
    });
  },

  /* misc stuff */

 nodeType: 1,

  //
  // jQuery-ish methods
  //

  find: function(sel) {
    throw new Error("Element#find is unimplemented");
  },

  //
  // debugging methods
  //

  inspect: function(refs, color, tainted) {
    var s = new wesabe.util.Colorizer();
    s.disabled = !color;
    s
      .reset()
      .bold('{'+(this.selfclosing ? 'empty' : '')+'elem ')
      .yellow('<')
      .white()
      .bold()
      .print(this.name);

    // print out the attributes
    this.attributes.forEach(function(attr) {
      var value = attr.nodeValue.toString();
      if (tainted) {
        value = wesabe.util.privacy.sanitize(value);
      }

      s
        .print(' ')
        .reset()
        .underlined(attr.nodeName)
        .yellow('="')
        .green(value)
        .yellow('"');
    });

    s.yellow('>');

    // print the children
    var hasElementChildren = false;
    this.__children__.forEach(function(child) {
      hasElementChildren = hasElementChildren || wesabe.is(child, wesabe.xml.Element);
      s.print(' ', wesabe.util._inspect(child, refs, color, tainted));
    });
    // only show the closing tag if there are child elements (not text)
    if (hasElementChildren) {
      s
        .print(' ')
        .yellow('</')
        .white()
        .bold()
        .print(this.name)
        .yellow('>');
    }
    return s.bold('}').toString();
  },
});
