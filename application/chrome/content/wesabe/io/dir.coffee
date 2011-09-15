################################################
################################################
#
# Basic JavaScript File and Directory IO module
# By: MonkeeSage, v0.1
# Modified for Wesabe by Brian Donovan
#
################################################
################################################
#
################################################
# Basic Directory IO object based on JSLib
# source code found at jslib.mozdev.org
################################################
#
# Example use:
# path = dir.open('/test')
# if path.exists()
#   alert dir.path path
#   children = dir.read path, true
#   if children
#     for child in children
#       alert child
# else
#   path = dir.create dir
#   alert "Directory create: #{path}"
#
# ---------------------------------------------
# ----------------- Nota Bene -----------------
# ---------------------------------------------
# Some possible types for get are:
#  'ProfD'       = profile
#  'DefProfRt'   = user (e.g., /root/.mozilla)
#  'UChrm'       = %profile%/chrome
#  'DefRt'       = installation
#  'PrfDef'      = %installation%/defaults/pref
#  'ProfDefNoLoc'= %installation%/defaults/profile
#  'APlugns'     = %installation%/plugins
#  'AChrom'      = %installation%/chrome
#  'ComsD'       = %installation%/components
#  'CurProcD'    = installation (usually)
#  'Home'        = OS root (e.g., /root)
#  'TmpD'        = OS tmp (e.g., /tmp)

{open} = require 'io/file'


sep        = if navigator.platform.toLowerCase().indexOf('win') > -1 then '\\' else '/'
dirservCID = '@mozilla.org/file/directory_service;1'
propsIID   = Components.interfaces.nsIProperties
fileIID    = Components.interfaces.nsIFile

_read = (dirEntry, recursive) ->
  list = []
  while dirEntry.hasMoreElements()
    list.push(dirEntry.getNext().QueryInterface(Components.interfaces.nsILocalFile))

  if recursive
    list2 = []
    for item in list
      if item.isDirectory()
        files = item.directoryEntries
        list2 = _read(files, recursive)

    list = list.concat(list2)

  return list


$dir =
  get: (type) ->
    try
      Components.classes[dirservCID].createInstance(propsIID).get(type, fileIID)
    catch e
      return false

  create: (dir) ->
    try
      dir.create 0x01, 0774
      return true
    catch e
      return false

  read: (dir, recursive=false) ->
    list = []
    wesabe.tryCatch "dir.read(#{dir})", =>
      if dir.isDirectory()
        files = dir.directoryEntries
        list = _read files, recursive
    return list

  unlink: (dir, recursive=false) ->
    try
      dir.remove recursive
      return true
    catch e
      return false

  path: (dir) ->
    FileIO.path(dir)

  split: (str, join='') ->
    str.split(/\/|\\/).join(join)

  join: (str, split) ->
    str.split(split).join(sep)


$dir.__defineGetter__ 'profile', ->
  $dir.get 'ProfD'

$dir.__defineGetter__ 'chrome', ->
  $dir.get 'AChrom'

$dir.__defineGetter__ 'root', ->
  file = open $dir.chrome.path + '/../../'
  file.normalize()
  return file

$dir.__defineGetter__ 'tmp', ->
  $dir.get 'TmpD'


module.exports = $dir
