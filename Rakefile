require "rake/clean"
require "rakelib/constants"
require "rakelib/platform"
require "rakelib/xulrunner"
require "rakelib/build"
require "rakelib/package"
require "rakelib/util"

Dir.glob('lib/tasks/*.rake').each {|f| load f}

APP_NAME = "Wesabe DesktopUploader"

task :default => [:build]

desc "Run the XulRunner application"
task :run => %w[run:server]

namespace :run do
  desc "Run the XulRunner application"
  task :server do
    system "script/server"
  end

  desc "Run a Ruby console connected to a running XulRunner application"
  task :console do
    system "script/console"
  end
end

desc "Installs XULRunner if necessary"
task :xulrunner => %w[xulrunner:ensure-installed]

desc "Build the application"
task :build => [:xulrunner] do
  platform.build
end

namespace :build do
  if macosx?
    desc "Build the application for development on Mac OS X"
    task :dev => :build do
      puts "linking application to your sources"

      resources_path = "build/#{APP_NAME}.app/Contents/Resources"
      FileUtils.rm_rf resources_path
      FileUtils.ln_s  "../../../application", resources_path
    end
  end
end

desc "Package the application"
task :package => [:build] do
  mkdir_p "dist"
  platform.package
end

desc "Clean all the built parts up"
task :clean do
  rm_rf "build"
  rm_rf "dist"
end

desc "Runs the tests for the Desktop Uploader (UNFINISHED)"
task :test do
  `open -a Firefox #{File.join(File.dirname(__FILE__), 'application', 'test', 'test_suite.html')}`
end
