wesabe.provide('lang.type');

wesabe.lang.type.isString = function(object) {
  return typeof(object) == 'string';
};

wesabe.lang.type.isNull = function(object) {
  return object === null;
};

wesabe.lang.type.isUndefined = function(object) {
  return typeof(object) == 'undefined';
};

wesabe.lang.type.isFunction = function(object) {
  return typeof(object) == 'function';
};

wesabe.lang.type.isBoolean = function(object) {
  return (object === true) || (object === false);
};

wesabe.lang.type.isFalse = function(object) {
  return object === false;
};

wesabe.lang.type.isTrue = function(object) {
  return object === true;
};

wesabe.lang.type.isNumber = function(object) {
  return typeof(object) == 'number';
};

wesabe.lang.type.isArray = function(object) {
  return object && 
         wesabe.lang.type.isNumber(object.length) &&
         wesabe.lang.type.isFunction(object.splice);
};

wesabe.lang.type.isObject = function(object) {
  return typeof(object) == 'object';
};

wesabe.lang.type.isDate = function(object) {
  return object && (object.constructor == Date || wesabe.isFunction(object.getMonth));
}

wesabe.lang.type.isTainted = function(object) {
  return object && object.isTainted && object.isTainted();
};

wesabe.lang.type.is = function(object, type) {
  return object && object.constructor == type;
};

wesabe.lang.extend(wesabe, wesabe.lang.type);