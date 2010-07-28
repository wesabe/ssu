wesabe.provide('lang.number', {
  ORDINAL_PARSERS: [
    [/\b(\w+)\s+from\s+last\b/i,  function(m){ if (m[1]) return -wesabe.lang.number.parseOrdinalPhrase(m[1]) }],
    [/(\d+)(st|rd|th|nd)/i,       function(m){ return parseInt(m[1]) }],
    [/\blast\b/i,              0],
    [/\bpenultimate\b/i,      -1],
    [/\bnext\s+to\s+last\b/i, -1],
    [/\bfirst\b/i,             1],
    [/\bsecond\b/i,            2],
    [/\bthird\b/i,             3],
    [/\bfourth\b/i,            4],
    [/\bfifth\b/i,             5],
    [/\bsixth\b/i,             6],
    [/\bseventh\b/i,           7],
    [/\beighth\b/i,            8],
    [/\bninth\b/i,             9],
    [/\btenth\b/i,            10],
  ],

  parseOrdinalPhrase: function(string) {
    var parsers = wesabe.lang.number.ORDINAL_PARSERS;

    for (var i = 0; i < parsers.length; i++) {
      var pattern = parsers[i][0],
          value = parsers[i][1],
          m = string.match(pattern);
      if (m) {
        if (wesabe.isFunction(value)) {
          return value(m);
        } else {
          return value;
        }
      }
    }
  },
});
