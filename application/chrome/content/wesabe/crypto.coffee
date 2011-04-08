try
  cryptoHash = Cc['@mozilla.org/security/hash;1'].createInstance(Ci.nsICryptoHash)
catch err
  wesabe.error('Could not load crypto package: ', err)

wesabe.provide 'crypto',
  # adapted from http://rcrowley.org/2007/11/15/md5-in-xulrunner-or-firefox-extensions/
  md5: (object) ->
    arr = []

    if wesabe.isArray(object)
      arr = object
    else if wesabe.isString(object)
      # Build array of character codes to MD5
      for i in [0...object.length]
        arr.push(object.charCodeAt(i))

    cryptoHash.init(Ci.nsICryptoHash.MD5)
    cryptoHash.update(arr, arr.length)
    hash = cryptoHash.finish(false)

    # Unpack the binary data bin2hex style
    ascii = []
    for i in [0...hash.length]
      c = hash.charCodeAt(i)
      ones = c % 16
      tens = c >> 4
      ascii.push(String.fromCharCode(tens + (if tens > 9 then 87 else 48)) +
                 String.fromCharCode(ones + (if ones > 9 then 87 else 48)))

    return ascii.join('')