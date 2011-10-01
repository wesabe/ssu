#
# Wesabe Desktop Uploader
# Copyright (C) 2007 Wesabe, Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

WESABE_LOGGER_CONTRACTID    = "@wesabe.com/logger;1"
WESABE_LOGGER_CID           = Components.ID("{0e2843fd-9579-4ec3-9321-f27e2b3c3fbc}")
WES_WUFF_LOG_TXT            = "wuff_log.txt"

Cc = Components.classes
Ci = Components.interfaces
Cr = Components.results

# global for cleanup - there's got to be a better way than a global!
wesLogFoutStream = null

pad = (n,c) ->
  n = n.toString()
  n = "0#{n}" until n.length >= c
  return n

getDateStr = ->
  d = new Date()
  "#{d.getFullYear()}.#{pad d.getMonth()+1, 2}.#{pad d.getDate(), 2} #{pad d.getHours(), 2}:#{pad d.getMinutes(), 2}:#{pad d.getSeconds(), 2}:#{pad d.getMilliseconds(), 3} #{pad d.getTimezoneOffset()/60, 2}"

class WesabeLogger
  constructor: ->
    try
      @mLog = Cc['@mozilla.org/consoleservice;1'].getService(Ci.nsIConsoleService)

      @fout = Cc["@mozilla.org/network/file-output-stream;1"].createInstance(Ci.nsIFileOutputStream)
      wesLogFoutStream = @fout
      file = @getLogFileByFileName WES_WUFF_LOG_TXT
      # file.append WES_WUFF_LOG_TXT
      @fout.init file, 0x02 | 0x08 | 0x10, 0664, 0
    catch ex
      dump "WesabeLogger error: #{ex.message}\n"

  QueryInterface: (iid) ->
    if iid.equals(Ci.nsIWesabeLogger) or iid.equals(Ci.nsISupports)
      return this

    throw Cr.NS_ERROR_NO_INTERFACE

  getLogFileByFileName: (name) ->
    path = @getPathForLogFileName name
    file = Cc['@mozilla.org/file/local;1'].createInstance(Ci.nsILocalFile)
    file.initWithPath(path)
    return file

  getPathForLogFileName: (name) ->
    ds = Cc["@mozilla.org/file/directory_service;1"].getService(Ci.nsIProperties)
    return "#{ds.get('ProfD', Ci.nsIFile).path}/#{name}"

  log: (msg) ->
    try
      date = getDateStr()

      for line in msg.split(/\r?\n/)
        logline = "#{date}: #{line}\n"
        @fout.write logline, logline.length
    catch ex
      dump "WesabeLogger error: log: #{ex.message}\n"

  debug: (args...) ->
    @log args...

  shutdown:
    observe: (subject, topic, data) ->
      try
        if topic is "quit-application"
          msg = getDateStr() +
            ": WesabeLogger: shutdown: closing " +
            WES_WUFF_LOG_TXT + "\n"
          wesLogFoutStream.write msg, msg.length
          wesLogFoutStream.close()
      catch ex
        dump "WesabeLogger error: shutdown: #{ex.message}\n"

WesabeLoggerFactory =
  singleton: null

  createInstance: (outer, iid) ->
    if outer isnt null
      throw Cr.NS_ERROR_NO_AGGREGATION

    if @singleton is null
      @singleton = new WesabeLogger()
      try
        observerService = Cc["@mozilla.org/observer-service;1"].getService(Ci.nsIObserverService)
        observerService.addObserver @singleton.shutdown, "quit-application", false
      catch ex
        dump "WesabeLoggerFactory: error on adding QAG observer: #{ex.message}\n"
    return @singleton.QueryInterface iid

WesabeLoggerModule =
  registerSelf: (compMgr, fileSpec, location, type) ->
    compMgr = compMgr.QueryInterface(Ci.nsIComponentRegistrar)
    compMgr.registerFactoryLocation WESABE_LOGGER_CID, "Wesabe Logger",
                                    WESABE_LOGGER_CONTRACTID, fileSpec, location, type

  unregisterSelf: (compMgr, fileSpec, location) ->

  getClassObject: (compMgr, cid, iid) ->
    if cid.equals(WESABE_LOGGER_CID)
      return WesabeLoggerFactory

    unless iid.equals Ci.nsIFactory
      throw Cr.NS_ERROR_NOT_IMPLEMENTED

    throw Cr.NS_ERROR_NO_INTERFACE

  canUnload: (compMgr) ->
    return true


@NSGetModule = (compMgr, fileSpec) ->
  WesabeLoggerModule
