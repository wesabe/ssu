wesabe.provide('xml.Document', function(xml) {
  if (xml) this.parse(xml);
});
wesabe.require('xml.*');

wesabe.lang.extend(wesabe.xml.Document.prototype, {
  get root() {
    if (!this._root)
      this._root = new wesabe.xml.Element();
    return this._root;
  },

  get documentElement() {
    return this.root.firstChild;
  },

  find: function(selector) {
    return this.documentElement.find(selector);
  },

  getElementById: function(id) {
    if (!this.documentElement)
      return null;

    return this.documentElement.getElementById(id);
  },

  getElementsByTagName: function(name) {
    if (!this.documentElement)
      return [];

    return this.documentElement.getElementsByTagName(name);
  },

  parse: function(xml, verboten) {
    var parser = new wesabe.xml.Parser(), root = this.root, context = root;

    var work = {
      root: root,

      context: context,

      stack: [],

      get top() {
        return work.stack[work.stack.length-1];
      },

      get unclosed() {
        for (var i = work.stack.length-1; i >= 0; i--) {
          var node = work.stack[i];
          if (node.parsing) return node;
        }
      },

      push: function(node) {
        if (wesabe.is(node, wesabe.xml.Text)) {
          work.stack.push(node);
          // work.unclosed.appendChild(node);
        } else if (wesabe.is(node, wesabe.xml.Attribute)) {
          work.top.setAttribute(node.name, node.value);
        } else if (wesabe.is(node, wesabe.xml.Element)) {
          node.parsing = !node.selfclosing;
          work.stack.push(node);
        } else {
          throw new Error('Unexpected node type: ', node);
        }
      },

      setName: function(name) {
        for (var i = work.stack.length-1; i >= 0; i--) {
          var node = work.stack[i];
          if (wesabe.is(node, wesabe.xml.Element)) {
            node.name = name;
            return;
          }
        }

        throw new Error('Unable to find an element to set name to ', name);
      },

      pop: function(closeTag) {
        // make sure tags are matched or just figure it out
        var node = null, popped = [];

        while (work.stack.length) {
          node = work.stack.pop();
          if (wesabe.is(node, wesabe.xml.Element) && node.parsing) {
            // found the matching opening tag, push all children into it
            if (node.name == closeTag.name) {
              popped.forEach(function(child) { node.appendChild(child) });
              delete node.parsing;
              work.stack.push(node);
              return;
            }
          } else if (node.parsing) {
            wesabe.error("NODE IS ", node);
          }

          // push a dangling text node onto the adjacent element if that element is unclosed
          if (wesabe.is(popped[0], wesabe.xml.Text) && wesabe.is(node, wesabe.xml.Element) && node.parsing) {
            node.appendChild(popped.shift());
          }
          popped.unshift(node);
        }

        throw new Error("Unexpected closing tag "+wesabe.util.inspect(closeTag));
      }
    };

    wesabe.bind(parser, 'start-open-tag', function(event, tag) {
      work.push(tag.toElement());
    });

    wesabe.bind(parser, 'end-open-tag', function(event, tag) {
      work.setName(tag.name);
    });

    wesabe.bind(parser, 'close-tag', function(event, tag) {
      work.pop(tag);
    });

    wesabe.bind(parser, 'text', function(event, text) {
      work.push(text);
    });

    wesabe.bind(parser, 'attribute', function(event, attr) {
      work.push(attr);
    });

    // parse the xml, executing all the callbacks above
    parser.parse(xml, verboten);

    work.root.appendChild(work.stack[0]);
  },

  inspect: function(refs, color, tainted) {
    var s = new wesabe.util.Colorizer();
    s.disabled = !color;
    s.yellow('#<')
     .bold(
       (this.constructor && this.constructor.__module__ && this.constructor.__module__.name) ||
       'Object')
    if (this.documentElement)
      s.print(' ', this.documentElement.inspect(refs, color, tainted))
    return s.yellow('>').toString();
  },
});
