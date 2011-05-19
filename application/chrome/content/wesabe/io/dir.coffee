wesabe.provide('io.dir')

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
# var dir = wesabe.io.dir.open('/test');
# if (dir.exists()) {
#  alert(wesabe.io.dir.path(dir));
#  var arr = wesabe.io.dir.read(dir, true), i;
#  if (arr) {
#    for (i = 0; i < arr.length; ++i) {
#      alert(arr[i].path);
#    }
#  }
# }
# else {
#  var rv = wesabe.io.dir.create(dir);
#  alert('Directory create: ' + rv);
# }
#
# ---------------------------------------------
# ----------------- Nota Bene -----------------
# ---------------------------------------------
# Some possible types for get are:
#  'ProfD'       = profile
#  'DefProfRt'     = user (e.g., /root/.mozilla)
#  'UChrm'       = %profile%/chrome
#  'DefRt'       = installation
#  'PrfDef'        = %installation%/defaults/pref
#  'ProfDefNoLoc'    = %installation%/defaults/profile
#  'APlugns'     = %installation%/plugins
#  'AChrom'        = %installation%/chrome
#  'ComsD'       = %installation%/components
#  'CurProcD'      = installation (usually)
#  'Home'        = OS root (e.g., /root)
#  'TmpD'        = OS tmp (e.g., /tmp)

wesabe.io.dir =
  sep        : '/'
  dirservCID : '@mozilla.org/file/directory_service;1'
  propsIID   : Components.interfaces.nsIProperties
  fileIID    : Components.interfaces.nsIFile

  get: (type) ->
    try
      dir = Components.classes[@dirservCID].createInstance(@propsIID).get(type, @fileIID)
      return dir
    catch e
      return false

  create: (dir) ->
    try
      dir.create(0x01, 0774)
      return true
    catch e
      return false

  read: (dir, recursive=false) ->
    list = []
    wesabe.tryCatch "wesabe.io.dir.read(#{dir})", =>
      if dir.isDirectory()
        files = dir.directoryEntries
        list = @_read(files, recursive)
    return list

  _read: (dirEntry, recursive) ->
    list = []
    while dirEntry.hasMoreElements()
      list.push(dirEntry.getNext().QueryInterface(Components.interfaces.nsILocalFile))

    if recursive
      list2 = []
      for item in list
        if item.isDirectory()
          files = item.directoryEntries
          list2 = @_read(files, recursive)

      list = list.concat(list2)

    return list

  unlink: (dir, recursive=false) ->
    try
      dir.remove(recursive)
      return true
    catch e
      return false

  path: (dir) ->
    FileIO.path(dir)

  split: (str, join='') ->
    str.split(/\/|\\/).join(join)

  join: (str, split) ->
    str.split(split).join(@sep)


wesabe.io.dir.__defineGetter__ 'profile', ->
  @get('ProfD')

wesabe.io.dir.__defineGetter__ 'chrome', ->
  @get('AChrom')

wesabe.io.dir.__defineGetter__ 'root', ->
  file = wesabe.io.file.open(@chrome.path + '/../../')
  file.normalize()
  return file

wesabe.io.dir.__defineGetter__ 'tmp', ->
  @get('TmpD')


wesabe.io.dir.sep = '\\' if navigator.platform.toLowerCase().indexOf('win') > -1
