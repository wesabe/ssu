#
# Wesabe Firefox Uploader
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

WCS_CID = Components.ID("{707ffd4c-2d95-4d04-af12-38c8137b387d}")

Cc = Components.classes
Ci = Components.interfaces
Cr = Components.results

class WesabeSniffer
  QueryInterface: (iid) ->
    if iid.equals(Ci.nsISupports) or iid.equals(Ci.nsIContentSniffer)
        return this
    throw Cr.NS_ERROR_NO_INTERFACE


  dataToString: (data) ->
    chars = ""
    shortCircuit = Math.min(data.length, 499)
    data = data[0...shortCircuit]
    for charCode in data
      if charCode isnt 0
        chars += String.fromCharCode charCode

    chars.replace /^\s+|\s+$/, ''

  getMIMETypeFromContent: (request, data, length) ->
    # dump "WesabeSniffer.getMIMETypeFromContent(#{request}, #{data}, #{length})\n"

    collecting = true
    if collecting
      # Checkable - data is uncompressed and available for inspection/verification of file type
      checkable = false
      try
        # chan = request.QueryInterface Ci.nsIChannel
        # dump "WesabeSniffer.getMTFC: mime-type: #{chan.contentType}\n"
        http = request.QueryInterface Ci.nsIHttpChannel
        compression = http.getResponseHeader "Content-Encoding"
        # dump "WesabeSniffer.getMTFC: encoding-type: #{compression}\n"
        # TODO: 12.4.2007 (tmason@wesabe.com) - use nsIStreamConverterService
        # (@mozilla.org/streamConverters;1) for a conversion from gzip to uncompressed.
      catch ex
        checkable = true

      ext = ""
      try
        http = request.QueryInterface Ci.nsIHttpChannel
        cdHeader = http.getResponseHeader "content-disposition"
        # dump "WesabeSniffer.getMTFC: content-disposition: #{cdHeader}\n"
        if cdHeader.length > 0
          cd = cdHeader.toLowerCase().split('filename=')
          if cd.length > 1 and cd[1].length > 0
            filename = cd[1]
            # dump "WesabeSniffer.getMTFC: filename: #{filename}}\n"
            ext = @sniffExt filename
            # dump "WesabeSniffer.getMTFC: sniffed extension revealed '#{ext}'\n"
      catch ex
        # do nothing - merely means the header does not exist

      if ext.length > 0 or checkable
        # dump "WesabeSniffer.getMTFC: --- Content sniffing --- "
        intercept = true
        stringData = @dataToString data
        # dump "WesabeSniffer: getMTFC: checking data: \n#{stringData[0...25]}\n"

        con = new FileTyper stringData
        # dump "WesabeSniffer: getMTFC: sniffed content revealed #{con.isSupportedType() and "supported" or "unsupported"} type: '#{con}' versus extension '#{ext}'\n"
        if con.isSupportedType() and ext.toUpperCase() isnt con.getType()
          ext = con.getType()

        if ext.length > 0
          try
            http = request.QueryInterface Ci.nsIHttpChannel

            # NOTE: We clear the Content-Disposition header because otherwise XulRunner will attempt
            # to present the file download prompt. We don't want that, but we do want the suggested
            # filename, so we try to save the original Content-Disposition header.
            try
              http.setResponseHeader "X-SSU-Content-Disposition", http.getResponseHeader("Content-Disposition"), false
            catch ex
              dump "WesabeSniffer.getMTFC: can't preserve Content-Disposition header: #{ex.message}\n"

            http.setResponseHeader "Content-Disposition", "", false
          catch ex
            dump "WesabeSniffer.getMTFC: can't unset content-disposition: #{ex.message}\n"

          try
            http = request.QueryInterface Ci.nsIHttpChannel

            try
              http.setResponseHeader "X-SSU-Content-Type", http.getResponseHeader("Content-Type"), false
            catch ex
              dump "WesabeSniffer.getMTFC: can't preserve Content-Type header: #{ex.message}\n"
          catch ex

          # dump "WesabeSniffer: getMTFC: marking request for intercept\n"
          return "application/x-ssu-intercept"

  sniffExt: (filename) ->
    ext = filename.match(/\.(\w+)/)?[1]?.toLowerCase()

    if ext in ['ofx', 'qif', 'ofc', 'qfx', 'pdf']
      ext
    else
      ''

WesabeSnifferFactory =
  createInstance: (outer, iid) ->
    if outer isnt null
      throw Cr.NS_ERROR_NO_AGGREGATION

    return new WesabeSniffer()


WesabeSnifferModule =
  firstTime: true

  registerSelf: (compMgr, fileSpec, location, type) ->
    compMgr = compMgr.QueryInterface Ci.nsIComponentRegistrar
    compMgr.registerFactoryLocation WCS_CID, "Wesabe Sniffer",
                                    "@wesabe.com/contentsniffer;1",
                                    fileSpec, location, type

  unregisterSelf: (compMgr, fileSpec, location) ->

  getClassObject: (compMgr, cid, iid) ->
    unless iid.equals Ci.nsIFactory
      throw Cr.NS_ERROR_NOT_IMPLEMENTED

    if cid.equals WCS_CID
      return WesabeSnifferFactory

    throw Cr.NS_ERROR_NO_INTERFACE

  canUnload: (compMgr) ->
    true

@NSGetModule = (compMgr, fileSpec) ->
  WesabeSnifferModule


# FileTyper - guess at the type of data file based on magic-number-like markers

TYPE =
  UNKNOWN : "UNKNOWN"
  OFX1    : "OFX/1"
  OFX2    : "OFX/2"
  OFC     : "OFC"
  QIF     : "QIF"
  PDF     : "PDF"
  HTML    : "HTML"
  MSMONEY : "MSMONEY-DB"

# These regexes are run in (random, I think) order over the contents,
# so be sure that none of the overlap.

MARKER =
  OFX1    : new RegExp('OFXHEADER:', "i")
  OFX2    : new RegExp('<?OFX OFXHEADER="200"', "i")
  OFC     : new RegExp('<OFC>', "i")
  QIF     : /(^\^(EUR)*\s*$)|(^!Type:)/im
  PDF     : /^%PDF-/
  HTML    : new RegExp('<HTML', "i")
  MSMONEY : new RegExp("MSMONEY-DB")

class FileTyper
  constructor: (@contents) ->
    @filetype = @_guessType()

  _guessType: ->
    # Try each format-specific marker in turn.
    for own marker, pattern of MARKER
      if pattern.test @contents
        return TYPE[marker]
    return TYPE.UNKNOWN

  getType: ->
    @filetype

  toString: ->
    @filetype

  isUnknown: ->
    @filetype is TYPE.UNKNOWN

  isSupportedType: ->
    @filetype in [TYPE.OFX1, TYPE.OFX2, TYPE.OFC, TYPE.QIF, TYPE.PDF]
