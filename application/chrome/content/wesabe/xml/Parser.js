wesabe.provide('xml.Parser', function(){});
wesabe.require('xml.*');

wesabe.lang.extend(wesabe.xml.Parser.prototype, {
  parse: function(xml, verboten) {
    var parser = this.parser = new wesabe.util.Parser(), self = this;

    wesabe.util.event.forward(parser, this);

    var work = this.work = {
      get el() { return work.__el__ },
      set el(el) {
        if (el && (el != work.el)) {
          el.parsed = false;
          el.offset = parser.offset - 1 /*<*/;
          work.nodes.push(el);
          el.beginParsing(parser);
        } else if (!el && work.__el__) {
          var oel = work.__el__;
          oel.doneParsing(parser);

          if (verboten && oel && wesabe.is(oel, wesabe.xml.OpenTag)) {
            if (verboten && oel && verboten.test(oel.name))
              self.skip();
          }
        }
        work.__el__ = el;
      },

      get attr() { return work.__attr__ },
      set attr(attr) {
        if (attr && (attr != work.attr)) {
          attr.parsed = false;
          attr.offset = parser.offset;
          work.nodes.push(attr);
          attr.beginParsing(parser);
        } else if (!attr && work.__attr__) {
          work.__attr__.doneParsing(parser);
        }
        work.__attr__ = attr;
      },

      get text() { return work.__text__ },
      set text(text) {
        if (text && (text != work.text)) {
          work.nodes.push(text);
          text.beginParsing(parser);
        } else if (!text && work.__text__) {
          work.__text__.doneParsing(parser);
        }
        work.__text__ = text;
      },

      nodes: []
    };

    // handles element nodes
    var el = {
      // <
      start: function() {
        parser.tokens = { '[a-zA-Z]': el.opening, '/': el.closing };
      },

      // first letter
      opening: function(p) {
        work.el = new wesabe.xml.OpenTag();
        el.name(p);
      },

      // subsequent characters
      name: function(p) {
        work.el.name += p;
        parser.tokens = { '[-_\.a-zA-Z0-9:]': el.name, '\\s': attr.prename, '>': el.end, '/': el.selfclosing };
      },

      // self-closing /
      selfclosing: function() {
        work.el.selfclosing = true;
        parser.tokens = { '>': el.end };
      },

      // </
      closing: function() {
        work.el = new wesabe.xml.CloseTag();
        parser.tokens = { '[a-zA-Z]': el.name };
      },

      // >
      end: function() {
        work.el = null;
        parser.tokens = { '<': el.start, '[^<]': text.start, EOF: noop };
      }
    };

    var attr = {
      // \s before attribute name
      prename: function() {
        parser.tokens = { '[a-zA-Z]': attr.start, '\\s': attr.prename, '>': attr.end };
      },

      // first [a-zA-Z]
      start: function(p) {
        work.attr = new wesabe.xml.Attribute();
        attr.name(p);
      },

      // subsequent [a-zA-Z]
      name: function(p) {
        work.attr.name += p;
        parser.tokens = { '[a-zA-Z:]': attr.name, '\\s': attr.postname, '=': attr.prevalue };
      },

      // \s after attribute name
      postname: function() {
        parser.tokens = { '\\s': attr.postname, '=': attr.prevalue };
      },

      // [=\s] before value
      prevalue: function() {
        parser.tokens = { '[a-zA-Z]': attr.value, '\\s': attr.prevalue, '[\'"]': attr.prequote };
      },

      // ['"] before value
      prequote: function(p) {
        work.attr.quote = p;
        attr.value();
      },

      // anything but work.attr.quote
      value: function(p) {
        if (!work.attr.quote) work.attr.quote = '\\s';
        var toks = { '>': attr.end };
        toks[work.attr.quote] = attr.postquote;
        toks['[^'+work.attr.quote+']'] = attr.value;
        parser.tokens = toks;
        if (p) work.attr.value += p;
      },

      // work.attr.quote
      postquote: function(p) {
        attr.end();
        if (/\s/.test(p)) attr.prename();
        else parser.tokens = { '>': el.end, '\\s': attr.prename, '/': el.selfclosing };
      },

      // > or work.attr.quote
      end: function(p) {
        work.attr = null;
        if (p == '>') el.end();
      }
    };

    // handles text nodes
    var text = {
      // first [^<]
      start: function(p) {
        work.text = new wesabe.xml.Text(p);
        parser.tokens = { '<': text.end, '[^<]': text.text, EOF: quit };
      },

      // subsequent [^<]
      text: function(p) {
        work.text.text += p;
      },

      // <
      end: function() {
        work.text = null;
        el.start();
      }
    };

    // do nothing
    var noop = function(){};
    // stop parsing
    var quit = function(){ return false };

    // initial parse setup
    parser.tokens = { '<': el.start, '\\s': noop };

    return wesabe.tryThrow('xml.Parser', function(log) {
      parser.parse(xml);
      delete self.parser;
      delete self.work;
      return work.nodes;
    });
  },

  stop: function() {
    if (this.parser) this.parser.stop();
  },

  skip: function() {
    if (!this.parser) return;
    var etag = '</'+this.work.el.name+'>';
    var offset = this.parser.parsing.indexOf(etag, this.parser.offset);
    if (offset >= this.parser.offset) this.parser.offset = offset-1;
    else throw new Error("Could not skip to "+etag+" because it is not present after offset "+this.parser.offset);
  },
});
