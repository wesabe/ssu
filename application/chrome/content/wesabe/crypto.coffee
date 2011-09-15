type = require 'lang/type'

md5 = null

try
  # assume we're in xulrunner
  cryptoHash = Cc['@mozilla.org/security/hash;1'].createInstance(Ci.nsICryptoHash)

  # adapted from https://developer.mozilla.org/en/nsICryptoHash#Computing_the_Hash_of_a_String
  md5 = (object) ->
    arr = []

    if type.isArray object
      arr = object
    else if type.isString object
      converter = Cc["@mozilla.org/intl/scriptableunicodeconverter"].createInstance(Ci.nsIScriptableUnicodeConverter)
      converter.charset = "UTF-8"
      arr = converter.convertToByteArray object, {}

    cryptoHash.init(Ci.nsICryptoHash.MD5)
    cryptoHash.update(arr, arr.length)
    hash = cryptoHash.finish(false)

    # Unpack the binary data bin2hex style
    return ("0#{hash.charCodeAt(i).toString(16)}".slice(-2) for c, i in hash).join('')

catch xulErr
  try
    # maybe we're in node.js
    crypto = require 'crypto'

    md5 = (object) ->
      crypto.createHash('md5').update(object).digest('hex')
  catch nodeErr
    wesabe.error 'Could not load xulrunner or node.js crypto package: ', xulErr, nodeErr


module.exports = {md5}
