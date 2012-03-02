fs = require 'fs'
Dir = null

dirAtPath = (path) ->
  Dir ||= require 'io/phantom/Dir'
  new Dir path

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
    fs.exists @path

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

  # Public: Gets the basename for this File.
  #
  # Examples
  #
  #   new File("/tmp/test.txt").basename
  #   # => 'test.txt'
  #
  # Returns a String representing this File's basename.
  @::__defineGetter__ 'basename', ->
    @constructor.basename @path

  # Public: Gets the basename for the given filePath.
  #
  # filePath - A String representing a full file path.
  #
  # Examples
  #
  #   File.basename("/tmp/test.txt")
  #   # => 'test.txt'
  #
  # Returns a String representing filePath's basename.
  @basename: (filePath) ->
    path.basename filePath

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
    dirAtPath(@path.slice(0, @path.length - @basename.length))

  # Public: Reads the entire contents of the file, starting at the beginning.
  #
  # encoding - A string indicating the encoding to use when reading this file.
  #
  # Returns a String with the file's contents.
  read: ->
    fs.read @path

  # Public: Reads the entire contents of the file, starting at the beginning.
  #
  # file - Either a File or a String representing a file path.
  # encoding - A string indicating the encoding to use when reading this file.
  #
  # Returns a String with the file's contents.
  @read: (file) ->
    file = new @ file if type.isString file
    file.read()

  # Public: Writes data with an optional type of encoding.
  #
  # data - A String containing the data to write to the file.
  # encoding - A string indicating the encoding to use when reading this file.
  #
  # Returns nothing.
  write: (data) ->
    fs.write @path, data, 'w'

  # Public: Writes data with an optional type of encoding.
  #
  # file - Either a File or a String representing a file path.
  # data - A String containing the data to write to the file.
  # encoding - A string indicating the encoding to use when reading this file.
  #
  # Returns nothing.
  @write: (file, data) ->
    file = new @ file if type.isString file
    file.write data

  # Public: Create the File at the path.
  #
  # Returns a Boolean indicating whether the creation succeeded.
  create: ->
    fs.touch @path unless fs.exists @path
    return true

  # Public: Removes this File from the file system.
  #
  # Returns a Boolean indicating whether the unlink succeeded.
  unlink: ->
    fs.remove @path

  # Public: Checks for file vs. directory type.
  #
  # Returns a Boolean indicating whether this File is actually a directory.
  @::__defineGetter__ 'isDirectory', ->
    fs.isDirectory @path

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
