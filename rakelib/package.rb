def package_macosx
  sh "/bin/ln -s /Applications build/Applications"
  mkdir "build/.background"
  cp "installer/resources/installer-bg.png", "build/.background/"
  sh "/usr/bin/sudo installer/mac/dmg_file.py -s build -d dist/Wesabe_DesktopUploader-0.0.1.dmg -v 'Wesabe DesktopUploader' -l installer/resources/License.txt"
end

def package_linux
  puts "Need recipie for packaging the application on Linux"
  exit
end

def package_windows
  puts "Need recipie for packaging the application on Windows"
  exit
end