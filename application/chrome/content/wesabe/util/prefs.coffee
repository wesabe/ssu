#
# Allows getting, setting, serializing, and deserializing preferences.
#

type    = require 'lang/type'
func    = require 'lang/func'
file    = require 'io/file'
inspect = wesabe.require 'util/inspect'

getPreferencesRoot = ->
  service = Components.classes['@mozilla.org/preferences-service;1']
    .getService(Components.interfaces.nsIPrefService)
  service.getBranch('')

#
# Loads preferences from a Mozilla prefs.js format preference file.
# Example:
#
#   $ cat prefs.js
#   # Mozilla Preference File
#   pref('network.proxy.http', 'proxy.oak.wesabe.com');
#   pref('network.proxy.http_port', 8080);
#   pref('network.proxy.type', 1);
#
#   wesabe.util.prefs.load('prefs.js');
#   wesabe.util.prefs.get('network.proxy.type'); // => 1
#
# WARNING: At this point this function is NOT SAFE and will eval the
# contents of the file in a non-safe way. Please know what you're doing.
#
load = (path) ->
  wesabe.tryCatch "prefs.load(#{path})", (log) =>
    data = file.read(path)

    if /^#/.test(data)
      # data includes unparseable first line, remove it
      data = data.replace(/^#[^\n]*/, '')

    func.callWithScope data, this, pref: set

#
# Get a preference by its full name. Example:
#
#   wesabe.util.prefs.get('browser.dom.window.dump.enabled'); // => false
#
get = (key, defaultValue) ->
  root = getPreferencesRoot()

  # maybe it's a String
  try
    return root.getCharPref(key)
  catch e

  # maybe it's a Boolean
  try
    return root.getBoolPref(key)
  catch e

  # maybe it's a Number
  try
    return root.getIntPref(key)
  catch e

  # not found
  return defaultValue

#
# Set a preference by its full name. Example:
#
#   prefs.set 'browser.dom.window.dump.enabled', true
#
set = (key, value) ->
  root = getPreferencesRoot()

  if type.isBoolean value
    root.setBoolPref key, value
  else if type.isString value
    root.setCharPref key, value
  else if type.isNumber value
    root.setIntPref key, value
  else
    throw new Error "Could not set preference for key=#{key}, unknown type for value=#{inspect value}"

#
# Clears a preference by its full name. Example:
#
#   wesabe.util.prefs.clear('general.useragent.override');
#
clear = (key) ->
  try
    getPreferencesRoot().clearUserPref(key)
  catch e
    # pref probably didn't exist, but make sure it's gone
    if not type.isUndefined get(key)
      wesabe.error "Could not clear pref with key=", key, " due to an error: ", e

module.exports = {load, get, set, clear}
