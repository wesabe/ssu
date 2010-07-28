wesabe.provide('lang.string', {
  trim: function(string) {
    return string.replace(/^\s+|\s+$/g, '');
  },

  substring: function(string, start, end) {
    if (start < 0) start += string.length;
    if (end === null || end === undefined) end = string.length-1;
    if (end < 0) end += string.length;
    return string.substring(start, end);
  },
});
