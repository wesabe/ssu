File = require 'io/node/File'
{tryThrow, tryCatch} = require 'util/try'
fs = require 'fs'

class Dir extends File
  # Public: Create the Dir at the path.
  #
  # Returns a Boolean indicating whether the creation succeeded.
  create: ->
    try
      fs.mkdirSync @path
      return true
    catch e
      return false

  # Public: Removes this Dir from the file system.
  #
  # Returns a Boolean indicating whether the unlink succeeded.
  unlink: (recursive=false) ->
    if recursive
      child.unlink recursive for child in children recursive

    fs.unlinkSync @path
    return true

  # Public: Gets a list of all Files in this Dir, optionally recursively.
  #
  # recursive - true if this should list all descendents, or just immediate descendants.
  #
  # Returns an Array of File instances.
  children: (recursive=false) ->
    list = for child in fs.readdirSync @path
      childPath = "#{@path}/#{child}"
      if fs.statSync(childPath).isDirectory()
        new Dir childPath
      else
        new File childPath

    if recursive
      for child in list
        if child.isDirectory
          list = list.concat child.children(recursive)

    return list

  @__defineGetter__ 'tmp', ->
    for tmp in ['TMPDIR', 'TMP', 'TEMP']
      return new @ process.env[tmp] if process.env[tmp]

    # fallback to the default
    return new @ '/tmp'


module.exports = Dir
