wesabe.provide('lang.array');

wesabe.lang.array = {
  from: function(object) {
    var retval = [];

    for (var i = 0; i < object.length; i++) {
      retval.push(object[i]);
    }

    return retval;
  },

  uniq: function(array) {
    var retval = [];

    for (var i = 0; i < array.length; i++) {
      if (!wesabe.lang.array.include(retval, array[i])) {
        retval.push(array[i]);
      }
    }

    return retval;
  },

  include: function(array, object) {
    object = wesabe.untaint(object);
    for (var i = 0; i < array.length; i++) {
      if (wesabe.untaint(array[i]) === object) return true;
    }
    return false;
  },

  compact: function(array) {
    var retval = [];

    for (var i = 0; i < array.length; i++) {
      if (wesabe.untaint(array[i])) retval.push(array[i]);
    }

    return retval;
  },

  equal: function(a, b) {
    if (a.length != b.length) {
      return false;
    } else {
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }
  },

  zip: function(array1, array2) {
    var result = [];

    for (var i = 0, l = Math.max(array1.length, array2.length); i < l; i++) {
      result.push([array1[i], array2[i]]);
    }

    return result;
  },
};
