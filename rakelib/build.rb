def build_macosx
  say "Assembling the application bundle"

  bundle = "build/#{APP_NAME}.app"
  xulrunner = "/Library/Frameworks/XUL.framework/xulrunner-bin"

  FileUtils.mkdir_p bundle
  FileUtils.rm_rf bundle # a bit harsh, but so far the most expedient
  system "#{xulrunner} --install-app application build"
  FileUtils.cp "resources/chart-mac-icon.icns", "#{bundle}/Contents/Resources/"
  FileUtils.cp "resources/Info.plist", "#{bundle}/Contents"
  FileUtils.mkdir_p "#{bundle}/Contents/Frameworks/XUL.framework/"
  system '/usr/bin/rsync', '-al', "#{XULFRAMEWORK}/", "#{bundle}/Contents/Frameworks/XUL.framework/"
end

def build_linux
  puts "Need recipe for building the application on Linux"
  exit
end

def build_windows
  puts "Need recipe for building the application on Windows"
  exit
end
