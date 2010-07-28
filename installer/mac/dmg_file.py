#!/usr/bin/env python

#
#  Copyright Wesabe, Inc. (c) 2005, 2006. All rights reserved.
#

# This class is quite a hack.  I combined a few different methods
# for making .dmg files on Mac because none of them did what I wanted
# on its own.  Right now a lot of the file placement code is hardcoded,
# and some of the methods are dead code, introduced while I was running
# experiments to get the damn thing to work.  Still, running this does
# actually produce the right output, and nearly nothing else does.  I'd
# recommend leaving this completely alone unless something totally breaks.
#
# If you do need to dig in, the Mozilla project has a pretty good perl
# script for making a .dmg, and Adium has some decent code (including the
# Applescript approach I take below).   

import optparse
import os
import re
import shutil
import StringIO
import subprocess
import textwrap

HDI_UTIL = '/usr/bin/hdiutil'
OSA_UTIL = '/usr/bin/osascript'
REZ_UTIL = '/Developer/Tools/Rez'
    
class DmgFile:
    def __init__(self, source_dir, volume_name=None, auto_open=True,
                 window_bounds=None, bgimage_file=None, icon_size=None,
                 license_path=None):
        self.source_dir   = source_dir
        self.volume_name  = volume_name
        self.license_path = license_path
        self.mount_dir    = "/Volumes/%s" % self.volume_name
    
    def position_file(self, file_name, left_position=None, top_position=None):
        # FIXME: 2006-10-09 <marc@wesabe.com> -- This method would be used
        # to position an icon in the resulting DMG.  Right now, that
        # information is hardcoded instead.
        pass
    
    def build(self, out_path):
        # Believe it or not, all these steps are actually necessary.
        raw_path    = out_path.replace('.dmg', '-RAW.dmg')
        hybrid_path = out_path.replace('.dmg', '-HYBRID.dmg')
        self._create_dmg(raw_path)
        raw_device = self._mount_image(raw_path)
        self._fixstyle(self.volume_name)
        self._fixperms(self.mount_dir)
        self._save_dsstore(self.mount_dir, self.source_dir)
        self._detach(raw_device)
        self._create_hybrid(hybrid_path)
        self._compress_dmg(hybrid_path, out_path)
        self._add_license(out_path)
        os.remove(raw_path)
        os.remove(hybrid_path)
    
    def _run_cmd(self, cmd, *arglist):
        s = cmd + ' ' + ' '.join(["%s"] * len(arglist)) % arglist
        print "Running command: %s\n" % s
        return os.system(s)
    
    def _run_sub(self, args, pipe=None):
        cmdline = ' '.join(args)
        print "Running subprocess: %s\n" % (cmdline)
        sub = subprocess.Popen(cmdline, shell=True, stdin=subprocess.PIPE,
                               stdout=subprocess.PIPE)
        if pipe is not None:
            sub.stdin.write(pipe)     #.encode('macroman'))
        sub.stdin.close()
        sub.wait()
        stdout = sub.stdout.read()
        return stdout
    
    def _create_dmg(self, out_path):
        return self._run_cmd(HDI_UTIL,
                             'create',
                             '-srcfolder', "'" + self.source_dir + "'",
                             '-volname', "'" + self.volume_name + "'",
                             '-fs', '"HFS+"',
                             '-fsargs', '"-c c=64,a=16,e=16"',
                             '-format', 'UDRW',
                             "'" + out_path + "'")
    
    def _create_hybrid(self, out_path):
        return self._run_cmd(HDI_UTIL,
                            'makehybrid',
                            '-ov', 
                            '-hfs',
                            '-hfs-openfolder', "'" + self.source_dir + "'",
                            '-hfs-volume-name', "'" + self.volume_name + "'",
                            '-o', "'" + out_path + "'",
                            "'" + self.source_dir + "'")
    
    def _mount_image(self, image_path):
        output = self._run_sub([HDI_UTIL,
                               'attach',
                               '-readwrite',
                               '-noverify',
                               '-noautoopen',
                               "'" + image_path + "'"])
        
        # Extract the device name (/dev/<foo>) for later use.
        pattern = re.compile("^(\S+)\s")
        match = pattern.match(output)
        if match is not None:
            device = match.group(1)
            print "Found device name: '%s'." % device
            return device
        else:
            return None
    
    def _fixstyle(self, volume_name):
        # This applescript method adjusts the Finder view of the 
        # output .dmg so that it looks right when the user opens
        # it on their machine.
        script = u"""tell application "Finder"
	tell disk ("%s" as string)
		open
		tell container window
			set current view to icon view
			set toolbar visible to false
			set statusbar visible to false
			set the bounds to {100, 100, 620, 388}
		end tell
		close
		set opts to the icon view options of container window
		tell opts
			set icon size to 72
			set arrangement to not arranged
		end tell
		set background picture of opts to file ".background:installer-bg.png"
		set position of item "XulUploader.app" to {130, 117}
		set position of item "Applications" to {400, 117}
		update without registering applications
		tell container window
			set the bounds to {101, 100, 620, 388}
			set the bounds to {100, 100, 620, 388}
		end tell
		update without registering applications
	end tell
	
	--give the finder some time to write the .DS_Store file
	delay 5
end tell
""" % volume_name
        f = os.popen(OSA_UTIL, 'w')
        f.write(script.encode('macroman'))
        f.close()

    def _fixperms(self, mount_dir):
        return self._run_cmd("chmod",
                             "-Rf",
                             "go-w",
                             "'" + mount_dir + "'")
    
    def _save_dsstore(self, volume_name, source_dir):
        shutil.copy(volume_name + "/.DS_Store", source_dir)
    
    def _detach(self, dev_name):
        return self._run_cmd(HDI_UTIL,
                             "detach",
                             "'" + dev_name + "'")
    
    def _compress_dmg(self, dmg_path, out_path):
        return self._run_cmd(HDI_UTIL,
                             'convert', dmg_path,
                             '-format', 'UDZO', 
                             '-imagekey', 'zlib-level=9',
                             '-o', "'" + out_path + "'")
    
    def _add_license(self, dmg_path):
        print self._run_cmd(HDI_UTIL, 'unflatten', "'" + dmg_path + "'")
        rsrc_path = dmg_path.replace('.dmg', '.r')
        self._make_license_resource(rsrc_path)
        print self._run_cmd(REZ_UTIL, 
                            "'" + rsrc_path + "'", 
                            '-a', 
                            '-o', "'" + dmg_path + "'")
        print self._run_cmd(HDI_UTIL, 'flatten', "'" + dmg_path + "'")
        os.remove(rsrc_path)
    
    def _make_license_line(self, raw_line):
        if raw_line == "\n":
            return '  \"\\n\"' + "\n"
        raw_line = raw_line.replace('\\', '\\\\')
        raw_line = raw_line.replace('"', '\\"')
        lines = textwrap.wrap(raw_line, 1000)
        if len(lines) > 1:
            print "WARNING: wrapping long license line at word boundry. " + \
                  "For better control over license format, make each " + \
                  "line of the license less than 1024 characters long."
        block = ""
        for line in lines:
            block += ('  \"%s\\n\"' + "\n") % line
        return block
    
    def _make_license_resource(self, rsrc_path):
        license = open(self.license_path, 'rU')
        license_lines = license.readlines()
        license.close()
        
        license_block = ""
        for line in license_lines:
            license_block += self._make_license_line(line)
        
        resource = """
// See /System/Library/Frameworks/CoreServices.framework/Frameworks/
// CarbonCore.framework/Headers/Script.h for language IDs.
#include <Carbon/Carbon.r>

data 'LPic' (5000) {
  // Default language ID, 0 = English
  $"0000"
  // Number of entries in list
  $"0001"
  
  // Entry 1
  // Language ID, 0 = English
  $"0000"
  // Resource ID, 0 = STR#/TEXT/styl 5000
  $"0000"
  // Multibyte language, 0 = no
  $"0000"
};

resource 'STR#' (5000, "English") {
  {
    // Language (unused?) = English
    "English",
    // Agree
    "I Accept",
    // Disagree
    "I Decline",
    // Print, ellipsis is 0xC9
    "Print\xc9",
    // Save As, ellipsis is 0xC9
    "Save As\xc9",
    // Descriptive text, curly quotes are 0xD2 and 0xD3
    "If you agree to the terms of this license "
    "agreement, click \xd2Agree\xd3 to access the software.  If you "
    "do not agree, press \xd2Disagree.\xd3"
  };
};

// Beware of 1024(?) byte (character?) line length limitation.  Split up long
// lines.
// If straight quotes are used ("), remember to escape them (\\").
// Newline is \\n, to leave a blank line, use two of them.
// 0xD2 and 0xD3 are curly double-quotes ("), 0xD4 and 0xD5 are curly
//   single quotes ('), 0xD5 is also the apostrophe.
data 'TEXT' (5000, "English") {
%s
};

data 'styl' (5000, "English") {
  // Number of styles following = 1
  $"0001"

  // Style 1.  This is used to display the first two lines in bold text.
  // Start character = 0
  $"0000 0000"
  // Height = 16
  $"0010"
  // Ascent = 12
  $"000C"
  // Font family = 1024 (Lucida Grande)
  $"0400"
  // Style bitfield, 0x1=bold 0x2=italic 0x4=underline 0x8=outline
  // 0x10=shadow 0x20=condensed 0x40=extended
  $"00"
  // Style, unused?
  $"02"
  // Size = 12 point
  $"000C"
  // Color, RGB
  $"0000 0000 0000"
};
""" % (license_block)
        
        license_rsrc = open(rsrc_path, 'w')
        license_rsrc.write(resource)
        license_rsrc.close()
    

if  __name__ == '__main__':
    parser = optparse.OptionParser()
    parser.add_option("-s", "--srcpath", dest="srcpath",
                      help="Path of the directory to package")
    parser.add_option("-d", "--dmgpath", dest="dmgpath",
                      help="Path of the dmg file to create")
    parser.add_option("-v", "--volume", dest="volume",
                      help="Name of the volume to create")
    parser.add_option("-l", "--license", dest="license",
                      help="License file path")
    (options, args) = parser.parse_args()
    dmg = DmgFile(options.srcpath, volume_name=options.volume, license_path=options.license)
    dmg.build(options.dmgpath)
    