wesabe.provide('dom.Selector');

wesabe.require('util.Parser');

wesabe.dom.Selector = function() {
  this.classNames = [];
};

wesabe.dom.Selector.prototype.__defineGetter__('className', function() {
  return this.classNames[this.classNames.length-1];
});

wesabe.dom.Selector.prototype.__defineSetter__('className', function(className) {
  this.classNames[this.classNames.length-1] = className;
});

wesabe.dom.Selector.prototype.test = function(el) {
  if (el.nodeType != 1) return false;
  if (this.id && this.id != el.id) return false;
  if (this.tag && this.tag != el.tagName) return false;
  for (var i = 0; i < this.classNames.length; i++) {
    var pattern = new RegExp(' '+this.classNames[i]+' ', 'i');
    wesabe.debug('pattern=', pattern, ' el.className=', el.className);
    if (!pattern.test(' '+el.className+' ')) return false;
  }
  return true;
};

wesabe.dom.Selector.parse = function(sel) {
  var parser = new wesabe.util.Parser();
  var selector = new wesabe.dom.Selector();
  
  var noop = function() {};
  
  var id = {
    start: function() {
      selector.id = '';
      parser.tokens = { '[a-zA-Z]': id.value }
    }, 
    
    value: function(p) {
      selector.id += p;
      parser.tokens = { '[-_a-zA-Z0-9]': id.value, '\\.': klass.start, EOF: noop };
    }
  };
  
  var klass = {
    // leading period
    start: function() {
      selector.classNames.push('');
      parser.tokens = { '[a-zA-Z]': klass.value };
    }, 
    
    // name of class
    value: function(p) {
      selector.className += p;
      parser.tokens = { '[-_a-zA-Z]': klass.value, '\\.': klass.start, EOF: noop };
    }
  };
  
  var tag = {
    // first tag character
    start: function(p) {
      selector.tag = p;
      parser.tokens = { '#': id.start, '[-_a-zA-Z0-9]': tag.value, '\\.': klass.start, EOF: noop };
    }, 
    
    // subsequent characters
    value: function(p) {
      selector.tag += p;
    }, 
    
    // *
    all: function() {
      tag.start();
      delete selector.tag;
    }
  };
  
  selector.raw = sel;
  parser.tokens = { '\\*': tag.all, '#': id.start, '[a-zA-Z]': tag.start, '\\.': klass.start, EOF: noop };
  
  wesabe.tryCatch('PARSING', function() {
    parser.parse(sel);
  });
  
  return selector;
};
