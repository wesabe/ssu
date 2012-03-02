File = require 'io/phantom/File'
fs = require 'fs'

class Dir extends File
  # Public: Create the Dir at the path.
  #
  # Returns a Boolean indicating whether the creation succeeded.
  create: ->
    try
      fs.makeDirectory @path
      return true
    catch e
      return false

  # Public: Removes this Dir from the file system.
  #
  # Returns a Boolean indicating whether the unlink succeeded.
  unlink: (recursive=false) ->
    if recursive
      fs.removeTree @path
    else
      fs.removeDirectory @path
    return true

  # Public: Gets a list of all Files in this Dir, optionally recursively.
  #
  # recursive - true if this should list all descendents, or just immediate descendants.
  #
  # Returns an Array of File instances.
  children: (recursive=false) ->
    list = for child in fs.list @path
      childPath = "#{@path}/#{child}"
      if fs.isDirectory childPath
        new Dir childPath
      else
        new File childPath

    if recursive
      for child in list
        if child.isDirectory
          list = list.concat child.children(recursive)

    return list

  @__defineGetter__ 'tmp', ->
    # phantom has no env access, so fallback to the default
    return new @ '/tmp'


module.exports = Dir
