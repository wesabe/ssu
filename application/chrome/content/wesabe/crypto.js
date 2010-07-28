(function() {
  try {
    var cryptoHash = Cc['@mozilla.org/security/hash;1'].createInstance(Ci.nsICryptoHash);
  } catch (err) {
    wesabe.error('Could not load crypto package: ', err);
  }

  wesabe.provide('crypto', {
    // adapted from http://rcrowley.org/2007/11/15/md5-in-xulrunner-or-firefox-extensions/
    md5: function(object) {
      var arr = [];

      if (wesabe.isArray(object)) {
        arr = object;
      } else if (wesabe.isString(object)) {
        // Build array of character codes to MD5
        var ii = object.length;
        for (var i = 0; i < ii; ++i) {
          arr.push(object.charCodeAt(i));
        }
      }

      cryptoHash.init(Ci.nsICryptoHash.MD5);
      cryptoHash.update(arr, arr.length);
      var hash = cryptoHash.finish(false);

      // Unpack the binary data bin2hex style
      var ascii = [];
      ii = hash.length;
      for (var i = 0; i < ii; ++i) {
        var c = hash.charCodeAt(i);
        var ones = c % 16;
        var tens = c >> 4;
        ascii.push(String.fromCharCode(tens + (tens > 9 ? 87 : 48)) +
          String.fromCharCode(ones + (ones > 9 ? 87 : 48)));
      }

      return ascii.join('');
    },
  });
})();
