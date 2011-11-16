# lazy-load some functions
untaint = (args...) ->
  {untaint} = require 'util/privacy'
  untaint args...
isFunction = (args...) ->
  {isFunction} = require 'lang/type'
  isFunction args...

ORDINAL_PARSERS = [
  [/\b(\w+)\s+from\s+(last|the\s+end)\b/i,  (m) -> -parseOrdinalPhrase(m[1]) if m[1]]
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

parseOrdinalPhrase = (string) ->
  for [pattern, value] in ORDINAL_PARSERS
    if m = string.match(pattern)
      value = value(m) if isFunction value
      return value

parse = (string) ->
  return NaN if string is ''

  if m = untaint(string).match /([\d,\.]+)/
    parts = m[1].replace(/,/g, '').split '.'
    if parts.length is 1
      Number parts[0]
    else
      fraction = parts.pop()
      Number(parts.join('')) + Number(fraction) / 100
  else
    NaN


module.exports = {parse, parseOrdinalPhrase}
