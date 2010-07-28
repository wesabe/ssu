wesabe.provide('lang');

wesabe.lang.extend = function(target, source, override) {
  override = (override !== false); // default to true
  
  for (var key in source) {
    if (source.hasOwnProperty(key)) {
      if (override || (typeof(target[key]) == 'undefined')) {
        var getter = source.__lookupGetter__(key), setter = source.__lookupSetter__(key);
        if (getter || setter) {
          if (getter) target.__defineGetter__(key, getter);
          if (setter) target.__defineSetter__(key, setter);
        } else {
          target[key] = source[key];
        }
      }
    }
  }
  
  return target;
};
