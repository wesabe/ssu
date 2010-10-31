wesabe.provide('io.process');
wesabe.require('io.file');
wesabe.require('io.dir');

wesabe.io.process = {
  get pid() {
    var process = Cc["@mozilla.org/process/util;1"].createInstance(Ci.nsIProcess);
    var pidhelper = wesabe.io.file.open(wesabe.io.dir.root.path+'/script/pidhelper');
    var pidfile = wesabe.io.file.open(wesabe.io.dir.root.path+'/pid'+(new Date().getTime()));

    process.init(pidhelper);
    var args = ['-p', '-o', pidfile.path];
    process.run(true, args, args.length);

    var pid = wesabe.io.file.read(pidfile);
    wesabe.io.file.unlink(pidfile);
    return pid && Number(pid);
  }
};
