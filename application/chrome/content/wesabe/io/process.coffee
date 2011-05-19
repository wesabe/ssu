wesabe.provide('io.process')
wesabe.require('io.file')
wesabe.require('io.dir')

wesabe.io.process.__defineGetter__ 'pid', ->
  process = Cc["@mozilla.org/process/util;1"].createInstance(Ci.nsIProcess)
  pidhelper = wesabe.io.file.open(wesabe.io.dir.root.path+'/script/pidhelper')
  pidfile = wesabe.io.file.open(wesabe.io.dir.root.path+'/pid'+(new Date().getTime()))

  process.init(pidhelper)
  args = ['-p', '-o', pidfile.path]
  process.run(true, args, args.length)

  pid = wesabe.io.file.read(pidfile)
  wesabe.io.file.unlink(pidfile)
  return pid && Number(pid)
