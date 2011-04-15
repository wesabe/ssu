wesabe.require('logger.*');
wesabe.logger.setLogger('file');

wesabe.require('download.*');
wesabe.require('util.*');
wesabe.require('io.*');
wesabe.require('ofx.*');

window.onerror = function(error, uri, errcode) {
  wesabe.error('uncaught exception at ', uri, ': ', error, ' (', errcode, ')');
};

function init() {
  wesabe.tryThrow('init', function(log) {
    wesabe.info('Initializing Server-Side Uploader v1.0');

    document.getElementById('menu_file').hidden = true;
    wesabe.util.privacy.clearAllPrivateData();

    var globalConfig = '/etc/ssu/xulrunner.js';

    if (wesabe.io.file.exists(globalConfig)) {
      log.info('Loading global preferences from ', globalConfig);
      wesabe.util.prefs.load(globalConfig);
    }

    wesabe.info('Logger level is ', wesabe.util.inspect(wesabe.logger.levelName));

    var cookies = wesabe.io.dir.profile.path+'/cookies';
    if (wesabe.io.file.exists(cookies)) {
      wesabe.tryCatch('Loading cookies from ' + cookies, function() {
        wesabe.util.cookies.restore(wesabe.io.file.read(wesabe.io.file.open(cookies)));
      });
    }

    var cmdLine = window.arguments[0];
    cmdLine = cmdLine.QueryInterface(Components.interfaces.nsICommandLine);

    if (cmdLine.handleFlag("verify-only", false)) {
      log.info("Verify-Only option used, exiting");
      return goQuitApplication();
    }

    var port = cmdLine.handleFlagWithParam("port", false);

    if (port)
      port = parseInt(port);

    var s = new wesabe.download.Controller();
    port = s.start(port);
    if (!port) {
      wesabe.fatal("Failed to start Controller, going down!");
      goQuitApplication();
    }

    var pid = wesabe.tryCatch('init(get pid)', function(){ return wesabe.io.process.pid });

    // write out our configuration so that whoever started us can talk to us
    var config = {
      port: port,
      version: wesabe.SSU_VERSION,
      pid: pid || null};
    var profile = wesabe.io.dir.profile;
    var file = wesabe.io.file.open(profile.path+'/config');
    log.debug('Writing configuration to ', file.path, ': ', config);
    wesabe.io.file.write(file, wesabe.lang.json.render(config));

    var pidFile = wesabe.io.file.open(profile.path+'/pid');
    wesabe.io.file.write(pidFile, ''+pid);

    var contentListener = wesabe.io.ContentListener.sharedInstance;
    contentListener.init(window, "application/x-wes-ofx");
    wesabe.bind(contentListener, 'after-receive', function(event, data) {
      wesabe.trigger('downloadSuccess', [data]);
    });
  });
}

const Cc = Components.classes;
const Ci = Components.interfaces;









window.addEventListener('load', init, false);

// Wesabe Sniffer registration - if not already registered.
var catMgr = Components.classes["@mozilla.org/categorymanager;1"]
                .getService(Components.interfaces.nsICategoryManager);
var addWesabeSniffer = true;
var cats = catMgr.enumerateCategories();
while (cats.hasMoreElements() && addWesabeSniffer) {
  var cat = cats.getNext();
  var catName = cat.QueryInterface(Components.interfaces.nsISupportsCString).data;
  if (catName === "net-content-sniffers") {
      var catEntries = catMgr.enumerateCategory(cat);
      while (catEntries.hasMoreElements()) {
      var catEntry = catEntries.getNext();
      var catEntryName =
        catEntry.QueryInterface(Components.interfaces.nsISupportsCString).data;
      if (catEntryName === "Wesabe Sniffer")
            addWesabeSniffer = false;
      }
  }
}
if (addWesabeSniffer) {
    catMgr.addCategoryEntry("net-content-sniffers", "Wesabe Sniffer", "@wesabe.com/contentsniffer;1", false, true);
}
