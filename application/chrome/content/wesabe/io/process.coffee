file   = require 'io/file'
dir    = require 'io/dir'
number = require 'lang/number'

class PID
  @::__defineGetter__ 'pid', ->
    return @_pid if @_pid

    process = Cc["@mozilla.org/process/util;1"].createInstance(Ci.nsIProcess)
    pidhelper = file.open "#{dir.root.path}/script/pidhelper"
    pidfile = file.open "#{dir.root.path}/pid#{new Date().getTime()}"

    process.init pidhelper
    args = ['-p', '-o', pidfile.path]
    process.run true, args, args.length

    pid = file.read pidfile
    file.unlink pidfile

    @_pid = number.parse(pid) if pid


module.exports = new PID
