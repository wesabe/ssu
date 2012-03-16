type = require 'lang/type'
{tryThrow, tryCatch} = require 'util/try'
Dir = null

dirAtPath = (path) ->
  Dir ||= require 'io/xulrunner/Dir'
  new Dir path

# Internal: Converts data from the given charset to unicode.
#
# charset - A String naming the encoding to convert data from.
# data - A String containing the data to convert.
#
# Returns a String in unicode encoding.
toUnicode = (charset, data) ->
  try
    uniConv = Cc['@mozilla.org/intl/scriptableunicodeconverter']
      .createInstance(Ci.nsIScriptableUnicodeConverter)
    uniConv.charset = charset
    data = uniConv.ConvertToUnicode(data)
  catch e
    # oh well

  return data

# Internal: Converts unicode data to the specified charset.
#
# charset - A String naming the encoding to convert data to.
# data - A String containing the data to convert.
#
# Returns a String in the encoding specified by charset.
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

# Public: Provides functions for reading and writing files.
#
# Examples
#
#   File.read 'us-declaration-of-independence.txt'
#   # => "When in the Course of human events it becomes necessary for one ..."
#
#   file = new File '/idontexistyet'
#   # => { File path: '/idontexistyet' }
#   file.exists
#   # => false
#   file.create()
#   file.exists
#   # => true
#
#   file = new File('/Users/donovan/Desktop/File.coffee')
#   while file
#     logger.debug file.basename
#     file = file.parent
#   # DEBUG File.coffee
#   # DEBUG Desktop
#   # DEBUG donovan
#   # DEBUG Users
#   # DEBUG
class File
  constructor: (@path) ->

  # Public: Tests for file existence.
  #
  # Examples
  #
  #   new File('/').exists
  #   # => true
  #
  #   new File('/idonotexist').exists
  #   # => false
  #
  # Returns a Boolean indicating whether this file exists.
  @::__defineGetter__ 'exists', ->
    @localFile.exists()

  # Internal: Gets the underlying nsILocalFile for this File's path.
  #
  # Returns an nsILocalFile.
  @::__defineGetter__ 'localFile', ->
    @_localFile ||= (=>
      file = Cc['@mozilla.org/file/local;1'].createInstance(Ci.nsILocalFile)
      file.initWithPath(@path)
      return file
    )()

  # Public: Gets a new File by appending a path component to this File's path.
  #
  # pathComponent - A String representing a path component to add.
  #
  # Examples
  #
  #   tmp = Dir.tmp
  #   # => { Dir path: '/tmp' }
  #   tmp.child 'test'
  #   # => { Dir path: '/tmp/test' }
  #
  # Returns a File representing a descendant of this File.
  child: (pathComponent) ->
    newPath = @path
    newPath += '/' unless newPath.substring(newPath.length-1) is '/'
    newPath += pathComponent
    new @constructor newPath

  # Public: Gets the number of bytes contained in this file.
  #
  # Returns a Number of bytes.
  @::__defineGetter__ 'size', ->
    @localFile.fileSize

  # Public: Gets the time at which this File was last modified.
  #
  # Returns a Date representing this File's last modified timestamp.
  @::__defineGetter__ 'lastModifiedTime', ->
    @localFile.lastModifiedTime

  # Public: Gets the basename for this File.
  #
  # Examples
  #
  #   new File("/tmp/test.txt").basename
  #   # => 'test.txt'
  #
  # Returns a String representing this File's basename.
  @::__defineGetter__ 'basename', ->
    @path.match(/\/([^\/]+)$/)?[1]

  # Public: Gets a Dir representing the same path as this File. This is useful
  # for converting a File into a Dir.
  #
  # Returns a Dir instance.
  @::__defineGetter__ 'asDir', ->
    dirAtPath @path

  # Public: Gets a File representing the same path as this File. This is useful
  # for converting a Dir into a File.
  #
  # Returns a File instance.
  @::__defineGetter__ 'asFile', ->
    new File @path

  # Public: Gets the parent Dir for this File.
  #
  # Returns a Dir representing this File's parent or null if it has no parent.
  @::__defineGetter__ 'parent', ->
    if path = @localFile.parent?.path
      dirAtPath path
    else
      null

  # Public: Normalize this File's path.
  #
  # Returns this File.
  normalize: ->
    @localFile.normalize()
    @path = @localFile.path
    return @

  # Public: Reads the entire contents of the file, starting at the beginning.
  #
  # encoding - A string indicating the encoding to use when reading this file.
  #
  # Returns a String with the file's contents.
  read: (encoding=null) ->
    tryThrow "File#read(#{@path})", =>
      fiStream = Cc['@mozilla.org/network/file-input-stream;1']
        .createInstance(Ci.nsIFileInputStream)
      siStream = Cc['@mozilla.org/scriptableinputstream;1']
        .createInstance(Ci.nsIScriptableInputStream)
      fiStream.init @localFile, 1, 0, false
      siStream.init fiStream

      data = siStream.read -1
      siStream.close()
      fiStream.close()
      data = toUnicode encoding, data if encoding

      return data

  # Public: Reads the entire contents of the file, starting at the beginning.
  #
  # file - Either a File or a String representing a file path.
  # encoding - A string indicating the encoding to use when reading this file.
  #
  # Returns a String with the file's contents.
  @read: (file, encoding=null) ->
    file = new @ file if type.isString file
    file.read encoding

  # Public: Writes data with an optional type of encoding.
  #
  # data - A String containing the data to write to the file.
  # mode - A standard file mode String.
  # encoding - A string indicating the encoding to use when reading this file.
  #
  # Returns nothing.
  write: (data, mode, encoding=null) ->
    try
      foStream = Cc['@mozilla.org/network/file-output-stream;1']
        .createInstance(Ci.nsIFileOutputStream)
      data = fromUnicode encoding, data if encoding
      flags = if mode == 'a'
                0x02 | 0x10        # wronly | append
              else
                0x02 | 0x08 | 0x20 # wronly | create | truncate

      foStream.init @localFile, flags, 0664, 0
      foStream.write data, data.length
      # foStream.flush()
      foStream.close()
      return true
    catch e
      logger.error 'File#write error: ', e
      return false

  # Public: Writes data with an optional type of encoding.
  #
  # file - Either a File or a String representing a file path.
  # data - A String containing the data to write to the file.
  # encoding - A string indicating the encoding to use when reading this file.
  #
  # Returns nothing.
  @write: (file, data, encoding=null) ->
    file = new @ file if type.isString file
    file.write data, encoding

  # Public: Create the File at the path.
  #
  # Returns a Boolean indicating whether the creation succeeded.
  create: ->
    try
      @localFile.create 0x00, 0664
      return true
    catch e
      return false

  # Public: Removes this File from the file system.
  #
  # Returns a Boolean indicating whether the unlink succeeded.
  unlink: ->
    try
      @localFile.remove false
      return true
    catch e
      return false

  # Public: Checks for file vs. directory type.
  #
  # Returns a Boolean indicating whether this File is actually a directory.
  @::__defineGetter__ 'isDirectory', ->
    @localFile.isDirectory()

  # Public: Gets a String representation.
  #
  # Returns a String of the path of this File.
  toString: ->
    @path

  # Internal: Gets the contents to show when inspecting this File.
  #
  # Returns an Object to use in place of this File's actual contents.
  contentForInspect: ->
    {@path}


module.exports = File
