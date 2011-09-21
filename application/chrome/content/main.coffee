#
# This is the main entry point into the XulRunner SSU application.
# It is loaded and eval'ed by main.xul in conjunction with CoffeeScript.
#
# Because it is not loaded using +require+, it does not have access to
# the nice things +require+ gives us, such as +logger+, +module+, etc.
# Please be aware of this difference when debugging this file.
#

# everyone else will get logging for free,
# but we need to set it up manually.
logger = (require 'Logger').loggerForFile 'main'


dir             = require 'io/dir'
file            = require 'io/file'
json            = require 'lang/json'
inspect         = require 'util/inspect'
cookies         = require 'util/cookies'
prefs           = require 'util/prefs'
privacy         = require 'util/privacy'
event           = require 'util/event'
Controller      = require 'download/Controller'
ContentListener = require 'io/ContentListener'
{tryThrow, tryCatch} = require 'util/try'


CONFIG = '/etc/ssu/xulrunner.js'


class Application
  constructor: (args) ->
    logger.info 'Initializing Server-Side Uploader v1.0'
    logger.info 'Logger level is ', inspect(logger.levelName)

    # clear all potentially identifying information
    privacy.clearAllPrivateData()

    @loadPrefs()
    @loadCookies()

    if args.on 'verify-only'
      logger.info "Verify-Only option used, exiting"
      return goQuitApplication()

    if not @startController {port: args.number 'port'}
      logger.fatal "Failed to start Controller, going down!"
      return goQuitApplication()

    # write out our configuration so that whoever started us can talk to us
    @writeConfig
      port: @controller.port
      pid: @pid or null

    @listenForDownloads()


  @::__defineGetter__ 'pid', ->
    @_pid ||= tryCatch 'init(get pid)', ->
      (require 'io/process').pid

  loadPrefs: ->
    if file.exists CONFIG
      logger.info 'Loading global preferences from ', CONFIG
      prefs.load CONFIG

  loadCookies: ->
    cookiesFile = dir.profile.path+'/cookies'
    if file.exists cookiesFile
      tryCatch 'Loading cookies from ' + cookiesFile, ->
        cookies.restore(file.read(file.open(cookiesFile)))

  startController: (options={}) ->
    @controller = new Controller()
    return @controller.start options.port

  writeConfig: (config) ->
    configFile = file.open "#{dir.profile.path}/config"
    logger.debug 'Writing configuration to ', configFile.path, ': ', config
    file.write configFile, json.render(config)

    pidFile = file.open "#{dir.profile.path}/pid"
    if config.pid
      file.write pidFile, "#{config.pid}"
    else if file.exists pidFile
      file.unlink pidFile

  listenForDownloads: ->
    contentListener = ContentListener.sharedInstance
    contentListener.init window, "application/x-ssu-intercept"
    event.add contentListener, 'after-receive', (event, data, filename) ->
      event.trigger 'downloadSuccess', [data, filename]


# Wesabe Sniffer registration - if not already registered.
catMgr = Components.classes["@mozilla.org/categorymanager;1"]
                .getService(Components.interfaces.nsICategoryManager)
addWesabeSniffer = true
cats = catMgr.enumerateCategories()
while cats.hasMoreElements() and addWesabeSniffer
  cat = cats.getNext()
  catName = cat.QueryInterface(Components.interfaces.nsISupportsCString).data
  if catName is "net-content-sniffers"
    catEntries = catMgr.enumerateCategory(cat)
    while catEntries.hasMoreElements()
      catEntry = catEntries.getNext()
      catEntryName = catEntry.QueryInterface(Components.interfaces.nsISupportsCString).data
      if catEntryName is "Wesabe Sniffer"
        addWesabeSniffer = false

if addWesabeSniffer
  catMgr.addCategoryEntry("net-content-sniffers", "Wesabe Sniffer", "@wesabe.com/contentsniffer;1", false, true)

class Arguments
  constructor: (@args) ->

  on: (flag) ->
    @cmdline.handleFlag flag, false

  string: (name) ->
    @cmdline.handleFlagWithParam name, false

  number: (name) ->
    if value = @string name
      Number(value)

  @::__defineGetter__ 'cmdline', ->
    @_cmdline ||= @args.QueryInterface(Components.interfaces.nsICommandLine)


new Application new Arguments(window.arguments[0])
