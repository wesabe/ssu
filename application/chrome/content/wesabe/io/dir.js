wesabe.provide('io.dir');

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
// Basic Directory IO object based on JSLib
// source code found at jslib.mozdev.org
/////////////////////////////////////////////////

// Example use:
// var dir = wesabe.io.dir.open('/test');
// if (dir.exists()) {
//  alert(wesabe.io.dir.path(dir));
//  var arr = wesabe.io.dir.read(dir, true), i;
//  if (arr) {
//    for (i = 0; i < arr.length; ++i) {
//      alert(arr[i].path);
//    }
//  }
// }
// else {
//  var rv = wesabe.io.dir.create(dir);
//  alert('Directory create: ' + rv);
// }

// ---------------------------------------------
// ----------------- Nota Bene -----------------
// ---------------------------------------------
// Some possible types for get are:
//  'ProfD'       = profile
//  'DefProfRt'     = user (e.g., /root/.mozilla)
//  'UChrm'       = %profile%/chrome
//  'DefRt'       = installation
//  'PrfDef'        = %installation%/defaults/pref
//  'ProfDefNoLoc'    = %installation%/defaults/profile
//  'APlugns'     = %installation%/plugins
//  'AChrom'        = %installation%/chrome
//  'ComsD'       = %installation%/components
//  'CurProcD'      = installation (usually)
//  'Home'        = OS root (e.g., /root)
//  'TmpD'        = OS tmp (e.g., /tmp)

wesabe.io.dir = {

  sep        : '/',

  dirservCID : '@mozilla.org/file/directory_service;1',

  propsIID   : Components.interfaces.nsIProperties,

  fileIID    : Components.interfaces.nsIFile,

  get    : function(type) {
    try {
      var dir = Components.classes[this.dirservCID]
              .createInstance(this.propsIID)
              .get(type, this.fileIID);
      return dir;
    }
    catch(e) {
      return false;
    }
  },

  get profile() {
    return wesabe.io.dir.get('ProfD');
  },

	get chrome() {
		return wesabe.io.dir.get('AChrom');
	},

	get root() {
		var file = wesabe.io.file.open(this.chrome.path + '/../../');
		file.normalize();
		return file;
	},

  get tmp() {
    return wesabe.io.dir.get('TmpD');
  },

  create : function(dir) {
    try {
      dir.create(0x01, 0774);
      return true;
    }
    catch(e) {
      return false;
    }
  },

  read   : function(dir, recursive) {
    var list = new Array();
    wesabe.tryCatch('wesabe.io.dir.read('+dir+')', function() {
      if (dir.isDirectory()) {
        if (recursive == null) {
          recursive = false;
        }
        var files = dir.directoryEntries;
        list = wesabe.io.dir._read(files, recursive);
      }
    });
    return list;
  },

  _read  : function(dirEntry, recursive) {
    var list = new Array();
    while (dirEntry.hasMoreElements()) {
      list.push(dirEntry.getNext()
              .QueryInterface(Ci.nsILocalFile));
    }
    if (recursive) {
      var list2 = new Array();
      for (var i = 0; i < list.length; ++i) {
        if (list[i].isDirectory()) {
          files = list[i].directoryEntries;
          list2 = wesabe.io.dir._read(files, recursive);
        }
      }
      for (i = 0; i < list2.length; ++i) {
        list.push(list2[i]);
      }
    }
    return list;
  },

  unlink : function(dir, recursive) {
    try {
      if (recursive == null) {
        recursive = false;
      }
      dir.remove(recursive);
      return true;
    }
    catch(e) {
      return false;
    }
  },

  path   : function (dir) {
    return FileIO.path(dir);
  },

  split  : function(str, join) {
    var arr = str.split(/\/|\\/), i;
    str = new String();
    for (i = 0; i < arr.length; ++i) {
      str += arr[i] + ((i != arr.length - 1) ?
                  join : '');
    }
    return str;
  },

  join   : function(str, split) {
    var arr = str.split(split), i;
    str = new String();
    for (i = 0; i < arr.length; ++i) {
      str += arr[i] + ((i != arr.length - 1) ?
                  this.sep : '');
    }
    return str;
  }

}

if (navigator.platform.toLowerCase().indexOf('win') > -1) {
  wesabe.io.dir.sep = '\\';
}
