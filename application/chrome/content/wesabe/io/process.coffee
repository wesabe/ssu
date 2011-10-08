File   = require 'io/File'
Dir    = require 'io/Dir'
number = require 'lang/number'

class PID
  @::__defineGetter__ 'pid', ->
    return @_pid if @_pid

    process = Cc["@mozilla.org/process/util;1"].createInstance(Ci.nsIProcess)
    pidhelper = Dir.root.child 'script/pidhelper'
    pidfile = Dir.root.child "pid#{new Date().getTime()}"

    process.init pidhelper.localFile
    args = ['-p', '-o', pidfile.path]
    process.run true, args, args.length

    pid = pidfile.read()
    pidfile.unlink()

    @_pid = number.parse(pid) if pid


module.exports = new PID
