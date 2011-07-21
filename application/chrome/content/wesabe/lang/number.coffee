wesabe.provide 'lang.number',
  ORDINAL_PARSERS: [
    [/\b(\w+)\s+from\s+(last|the\s+end)\b/i,  (m) -> -wesabe.lang.number.parseOrdinalPhrase(m[1]) if m[1]]
    [/([\d,]+)(st|rd|th|nd)/i,                (m) -> Number(m[1].replace(',', ''))]
    [/\blast\b/i,              0]
    [/\bpenultimate\b/i,      -1]
    [/\bnext\s+to\s+last\b/i, -1]
    [/\bfirst\b/i,             1]
    [/\bsecond\b/i,            2]
    [/\bthird\b/i,             3]
    [/\bfourth\b/i,            4]
    [/\bfifth\b/i,             5]
    [/\bsixth\b/i,             6]
    [/\bseventh\b/i,           7]
    [/\beighth\b/i,            8]
    [/\bninth\b/i,             9]
    [/\btenth\b/i,            10]
  ]

  parseOrdinalPhrase: (string) ->
    for [pattern, value] in @ORDINAL_PARSERS
      if m = string.match(pattern)
        value = value(m) if wesabe.isFunction(value)
        return value

  parse: (string) ->
    parseInt(wesabe.untaint(string), 10)
