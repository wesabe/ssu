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
# var fileIn = file.open('/test.txt');
# if (fileIn.exists()) {
#  var fileOut = file.open('/copy of test.txt');
#  var str = file.read(fileIn);
#  var rv = file.write(fileOut, str);
#  alert('File write: ' + rv);
#  rv = file.write(fileOut, str, 'a');
#  alert('File append: ' + rv);
#  rv = file.unlink(fileOut);
#  alert('File unlink: ' + rv);
# }

type = require 'lang/type'
{tryThrow, tryCatch} = require 'util/try'

exists = (path) ->
  open(path)?.exists()

open = (path) ->
  try
    file = Cc['@mozilla.org/file/local;1'].createInstance(Ci.nsILocalFile)
    file.initWithPath(path)
    return file
  catch e
    null

read = (file, charset) ->
  if type.isString file
    path = file
    file = open path
  else if file
    path = file.path

  tryThrow "file.read(#{path})", =>
    fiStream = Cc['@mozilla.org/network/file-input-stream;1']
      .createInstance(Ci.nsIFileInputStream)
    siStream = Cc['@mozilla.org/scriptableinputstream;1']
      .createInstance(Ci.nsIScriptableInputStream)
    fiStream.init(file, 1, 0, false)
    siStream.init(fiStream)

    data = siStream.read(-1)
    siStream.close()
    fiStream.close()
    data = toUnicode charset, data if charset

    return data

eachLine = (file, callback) ->
  stream = IO.newInputStream(file, "text")
  while stream.available()
    callback stream.readLine()

write = (file, data, mode, charset) ->
  if type.isString file
    path = file
    file = open path
  else if file
    path = file.path

  try
    foStream = Cc['@mozilla.org/network/file-output-stream;1']
      .createInstance(Ci.nsIFileOutputStream)
    data = fromUnicode charset, data if charset
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
    logger.error 'file.write error: ', e
    return false

create = (file) ->
  try
    file.create(0x00, 0664)
    return true
  catch e
    return false

unlink = (file) ->
  try
    file.remove(false)
    return true
  catch e
    return false

path = (file) ->
  try
    "file:///#{file.path.replace(/\\/g, '\/')
          .replace(/^\s*\/?/, '').replace(/\ /g, '%20')}"
  catch e
    return false

toUnicode = (charset, data) ->
  try
    uniConv = Cc['@mozilla.org/intl/scriptableunicodeconverter']
      .createInstance(Ci.nsIScriptableUnicodeConverter)
    uniConv.charset = charset
    data = uniConv.ConvertToUnicode(data)
  catch e
    # oh well

  return data

fromUnicode = (charset, data) ->
  try
    uniConv = Cc['@mozilla.org/intl/scriptableunicodeconverter']
      .createInstance(Ci.nsIScriptableUnicodeConverter)
    uniConv.charset = charset
    data = uniConv.ConvertFromUnicode(data)
    # data += uniConv.Finish()
  catch e
    # oh well

  return data

module.exports = {open, exists, read, create, unlink, path, write}
