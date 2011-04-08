wesabe.provide('io.file')

#################################################
#################################################
#
# Basic JavaScript File and Directory IO module
# By: MonkeeSage, v0.1
# Modified for Wesabe by Brian Donovan
#
################################################
################################################

################################################
# Basic file IO object based on Mozilla source
# code post at forums.mozillazine.org
################################################

# Example use:
# var fileIn = wesabe.io.file.open('/test.txt');
# if (fileIn.exists()) {
#  var fileOut = wesabe.io.file.open('/copy of test.txt');
#  var str = wesabe.io.file.read(fileIn);
#  var rv = wesabe.io.file.write(fileOut, str);
#  alert('File write: ' + rv);
#  rv = wesabe.io.file.write(fileOut, str, 'a');
#  alert('File append: ' + rv);
#  rv = wesabe.io.file.unlink(fileOut);
#  alert('File unlink: ' + rv);
# }

wesabe.io.file =

  localfileCID  : '@mozilla.org/file/local;1'
  localfileIID  : Components.interfaces.nsILocalFile

  finstreamCID  : '@mozilla.org/network/file-input-stream;1'
  finstreamIID  : Components.interfaces.nsIFileInputStream

  foutstreamCID : '@mozilla.org/network/file-output-stream;1'
  foutstreamIID : Components.interfaces.nsIFileOutputStream

  sinstreamCID  : '@mozilla.org/scriptableinputstream;1'
  sinstreamIID  : Components.interfaces.nsIScriptableInputStream

  suniconvCID   : '@mozilla.org/intl/scriptableunicodeconverter'
  suniconvIID   : Components.interfaces.nsIScriptableUnicodeConverter

  exists: (path) ->
    @open(path)?.exists()

  open: (path) ->
    try
      file = Components.classes[@localfileCID].createInstance(@localfileIID)
      file.initWithPath(path)
      return file
    catch e
      false

  read: (file, charset) ->
    if wesabe.isString(file)
      path = file
      file = @open(path)
    else if file
      path = file.path

    wesabe.tryThrow "wesabe.io.file.read(#{path})", =>
      fiStream = Components.classes[@finstreamCID].createInstance(@finstreamIID)
      siStream = Components.classes[@sinstreamCID].createInstance(@sinstreamIID)
      fiStream.init(file, 1, 0, false)
      siStream.init(fiStream)

      data = siStream.read(-1)
      siStream.close()
      fiStream.close()
      data = @toUnicode(charset, data) if charset

      return data

  eachLine: (file, callback) ->
    stream = IO.newInputStream(file, "text")
    while stream.available()
      callback(stream.readLine())

  write: (file, data, mode, charset) ->
    try
      foStream = Components.classes[@foutstreamCID].createInstance(@foutstreamIID)
      data = @fromUnicode(charset, data) if charset
      flags = if mode == 'a'
                0x02 | 0x10        # wronly | append
              else
                0x02 | 0x08 | 0x20 # wronly | create | truncate

      foStream.init(file, flags, 0664, 0)
      foStream.write(data, data.length)
      # foStream.flush()
      foStream.close()
      return true
    catch e
      wesabe.error('wesabe.io.file.write error: ', e)
      return false

  create: (file) ->
    try
      file.create(0x00, 0664)
      return true
    catch e
      return false

  unlink: (file) ->
    try
      file.remove(false)
      return true
    catch e
      return false

  path: (file) ->
    try
      "file:///#{file.path.replace(/\\/g, '\/')
            .replace(/^\s*\/?/, '').replace(/\ /g, '%20')}"
    catch e
      return false

  toUnicode: (charset, data) ->
    try
      uniConv = Components.classes[@suniconvCID].createInstance(@suniconvIID)
      uniConv.charset = charset
      data = uniConv.ConvertToUnicode(data)
    catch e
      # oh well

    return data

  fromUnicode: (charset, data) ->
    try
      uniConv = Components.classes[@suniconvCID].createInstance(@suniconvIID)
      uniConv.charset = charset
      data = uniConv.ConvertFromUnicode(data)
      # data += uniConv.Finish()
    catch e
      # oh well

    return data
