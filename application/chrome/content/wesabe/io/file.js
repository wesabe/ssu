wesabe.provide('io.file');

/////////////////////////////////////////////////
/////////////////////////////////////////////////
//
// Basic JavaScript File and Directory IO module
// By: MonkeeSage, v0.1
// Modified for Wesabe by Brian Donovan
//
/////////////////////////////////////////////////
/////////////////////////////////////////////////

/////////////////////////////////////////////////
// Basic file IO object based on Mozilla source
// code post at forums.mozillazine.org
/////////////////////////////////////////////////

// Example use:
// var fileIn = wesabe.io.file.open('/test.txt');
// if (fileIn.exists()) {
//  var fileOut = wesabe.io.file.open('/copy of test.txt');
//  var str = wesabe.io.file.read(fileIn);
//  var rv = wesabe.io.file.write(fileOut, str);
//  alert('File write: ' + rv);
//  rv = wesabe.io.file.write(fileOut, str, 'a');
//  alert('File append: ' + rv);
//  rv = wesabe.io.file.unlink(fileOut);
//  alert('File unlink: ' + rv);
// }

wesabe.io.file = {

  localfileCID  : '@mozilla.org/file/local;1',
  localfileIID  : Components.interfaces.nsILocalFile,

  finstreamCID  : '@mozilla.org/network/file-input-stream;1',
  finstreamIID  : Components.interfaces.nsIFileInputStream,

  foutstreamCID : '@mozilla.org/network/file-output-stream;1',
  foutstreamIID : Components.interfaces.nsIFileOutputStream,

  sinstreamCID  : '@mozilla.org/scriptableinputstream;1',
  sinstreamIID  : Components.interfaces.nsIScriptableInputStream,

  suniconvCID   : '@mozilla.org/intl/scriptableunicodeconverter',
  suniconvIID   : Components.interfaces.nsIScriptableUnicodeConverter,

  exists: function(path) {
    var file = wesabe.io.file.open(path);
    return file && file.exists();
  },

  open   : function(path) {
    try {
      var file = Components.classes[this.localfileCID]
              .createInstance(this.localfileIID);
      file.initWithPath(path);
      return file;
    }
    catch(e) {
      return false;
    }
  },

  read   : function(file, charset) {
    var self = this;

    var path;
    if (wesabe.isString(file)) {
      path = file;
      file = wesabe.io.file.open(path);
    } else if (file) {
      path = file.path;
    }

    return wesabe.tryThrow('wesabe.io.file.read('+path+')', function() {
      var data     = new String();
      var fiStream = Components.classes[self.finstreamCID]
                .createInstance(self.finstreamIID);
      var siStream = Components.classes[self.sinstreamCID]
                .createInstance(self.sinstreamIID);
      fiStream.init(file, 1, 0, false);
      siStream.init(fiStream);
      data += siStream.read(-1);
      siStream.close();
      fiStream.close();
      if (charset) {
        data = self.toUnicode(charset, data);
      }
      return data;
    });
  },

  eachLine: function(file, callback) {
    var stream = IO.newInputStream(file, "text");
    while (stream.available())
      callback(stream.readLine());
  },

  write  : function(file, data, mode, charset) {
    try {
      var foStream = Components.classes[this.foutstreamCID]
                .createInstance(this.foutstreamIID);
      if (charset) {
        data = this.fromUnicode(charset, data);
      }
      var flags = 0x02 | 0x08 | 0x20; // wronly | create | truncate
      if (mode == 'a') {
        flags = 0x02 | 0x10; // wronly | append
      }
      foStream.init(file, flags, 0664, 0);
      foStream.write(data, data.length);
      // foStream.flush();
      foStream.close();
      return true;
    }
    catch(e) {
      wesabe.error('wesabe.io.file.write error: ', e);
      return false;
    }
  },

  create : function(file) {
    try {
      file.create(0x00, 0664);
      return true;
    }
    catch(e) {
      return false;
    }
  },

  unlink : function(file) {
    try {
      file.remove(false);
      return true;
    }
    catch(e) {
      return false;
    }
  },

  path   : function(file) {
    try {
      return 'file:///' + file.path.replace(/\\/g, '\/')
            .replace(/^\s*\/?/, '').replace(/\ /g, '%20');
    }
    catch(e) {
      return false;
    }
  },

  toUnicode   : function(charset, data) {
    try{
      var uniConv = Components.classes[this.suniconvCID]
                .createInstance(this.suniconvIID);
      uniConv.charset = charset;
      data = uniConv.ConvertToUnicode(data);
    }
    catch(e) {
      // foobar!
    }
    return data;
  },

  fromUnicode : function(charset, data) {
    try {
      var uniConv = Components.classes[this.suniconvCID]
                .createInstance(this.suniconvIID);
      uniConv.charset = charset;
      data = uniConv.ConvertFromUnicode(data);
      // data += uniConv.Finish();
    }
    catch(e) {
      // foobar!
    }
    return data;
  }

};
