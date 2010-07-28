wesabe.provide('lang.json');

wesabe.lang.json = {
  parse: function(string) {
    return eval('(' + string + ')');
  }, 
  
  render: function(object) {
    return wesabe.lang.json._render(object, []);
  }, 
  
  _render: function(object, refs) {
    for (var i = 0; i < refs.length; i++)
      if (refs[i] === object) return wesabe.lang.json._render('$$ circular reference $$', refs);
    
    if (wesabe.isString(object))
      return wesabe.lang.json._renderString(object);
    if (wesabe.isNull(object))
      return wesabe.lang.json._renderNull(object);
    if (wesabe.isUndefined(object))
      return wesabe.lang.json._renderUndefined(object);
    if (wesabe.isArray(object))
      return wesabe.lang.json._renderArray(object, refs);
    if (wesabe.isNumber(object))
      return wesabe.lang.json._renderNumber(object);
    if (wesabe.isBoolean(object))
      return wesabe.lang.json._renderBoolean(object);
    if (wesabe.isObject(object))
      return wesabe.lang.json._renderObject(object, refs);
    wesabe.error('could not identify type for: ', object);
  }, 
  
  _renderString: function(string) {
    var map = {"\n": "\\n", "\t": "\\t", '"': '\\"'};
    return '"'+string.replace(/./g, function(s) {
      return map[s] || (/[\u00FF-\uFFFF]/.test(s) ? ('\\u'+s.charCodeAt(0).toString(16)) : s)
    })+'"';
  }, 
  
  _renderArray: function(array, refs) {
    refs.push(array);
    return '['+array.map(function(el){ return wesabe.lang.json._render(el, refs) }).join(', ')+']';
  }, 
  
  _renderBoolean: function(bool) {
    return bool.toString();
  }, 
  
  _renderObject: function(object, refs) {
    refs.push(object);
    var attrs = [];
    for (var key in object) {
      if (wesabe.isFunction(object[key])) continue;
      var value = wesabe.lang.json._render(object[key], refs);
      if (value !== undefined)
        attrs.push(wesabe.lang.json._render(key, refs)+': '+value);
    }
    return '{' + attrs.join(', ') + '}';
  }, 
  
  _renderNumber: function(number) {
    return number.toString();
  }, 
  
  _renderNull: function() {
    return 'null';
  }, 
  
  _renderUndefined: function() {
    return 'null';
  }
};
