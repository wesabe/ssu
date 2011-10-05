# emulate the node.js crypto module
type = require 'lang/type'

# adapted from https://developer.mozilla.org/en/nsICryptoHash#Computing_the_Hash_of_a_String
class Hash
  constructor: (@algorithm) ->
    @_impl = Cc['@mozilla.org/security/hash;1'].createInstance(Ci.nsICryptoHash)

  update: (data) ->
    if type.isArray data
      arr = data
    else if type.isString data
      converter = Cc["@mozilla.org/intl/scriptableunicodeconverter"].createInstance(Ci.nsIScriptableUnicodeConverter)
      converter.charset = "UTF-8"
      arr = converter.convertToByteArray data, {}

    @_impl.init @algorithm
    @_impl.update arr, arr.length

    return this

  digest: (format) ->
    hash = @_impl.finish false

    switch format
      when 'hex'
        # Unpack the binary data bin2hex style
        return ("0#{hash.charCodeAt(i).toString(16)}".slice(-2) for c, i in hash).join('')
      else
        throw new Error "unknown digest format #{format}"

createHash = (algorithmName) ->
  switch algorithmName
    when 'md5'
      return new Hash Ci.nsICryptoHash.MD5
    else
      throw new Error "unknown crypto algorithm #{algorithmName}"


module.exports = {createHash}
