File = require 'io/xulrunner/File'
{tryThrow, tryCatch} = require 'util/try'

# Internal: Gets a special Dir by name.
#
# name - The name of the special directory to get, such as ProfD.
#
# Returns a Dir representing a special directory.
getNamedDir = (name) ->
  try
    new Dir Cc['@mozilla.org/file/directory_service;1']
      .createInstance(Ci.nsIProperties)
      .get(name, Ci.nsIFile)
      .path
  catch e
    return false


class Dir extends File
  # Public: Create the Dir at the path.
  #
  # Returns a Boolean indicating whether the creation succeeded.
  create: ->
    try
      @localFile.create 0x01, 0774
      return true
    catch e
      return false

  # Public: Removes this Dir from the file system.
  #
  # Returns a Boolean indicating whether the unlink succeeded.
  unlink: (recursive=false) ->
    try
      @localFile.remove recursive
      return true
    catch e
      return false

  # Public: Gets a list of all Files in this Dir, optionally recursively.
  #
  # recursive - true if this should list all descendents, or just immediate descendants.
  #
  # Returns an Array of File instances.
  children: (recursive=false) ->
    list = []
    entries = @localFile.directoryEntries
    while entries.hasMoreElements()
      entry = entries.getNext().QueryInterface(Ci.nsILocalFile)
      list.push entry.isDirectory() and new Dir(entry.path) or new File(entry.path)

    if recursive
      for child in list
        if child.isDirectory
          list = list.concat child.children(recursive)

    return list


  @__defineGetter__ 'profile', ->
    getNamedDir 'ProfD'

  @__defineGetter__ 'chrome', ->
    getNamedDir 'AChrom'

  @__defineGetter__ 'root', ->
    (new @ "#{@chrome.path}/../../").normalize()

  @__defineGetter__ 'tmp', ->
    getNamedDir 'TmpD'


module.exports = Dir
