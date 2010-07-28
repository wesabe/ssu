wesabe.provide('io.process');
wesabe.require('io.file');

wesabe.io.process = {
  get pid() {
    if (!wesabe.io.file.exists('/proc/self')) {
      wesabe.warn("No proc-fs so I can't determine my PID");
    }
    else {
      var procdir = wesabe.io.file.open('/proc/self');
      procdir.normalize();
      var m = procdir.path.match(/(\d+)$/);
      return m && parseInt(m[1]);
    }
  }
};
