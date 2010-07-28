namespace :xulrunner do
  desc "Install the XULRunner framework"
  task 'install' do
    platform.derivative(Xulrunner::Installer).install(XULVERSION)
  end

  task 'ensure-installed' do
    framework = platform.derivative(Xulrunner::Framework).new

    if framework.installed?
      say "Skipping install of XULRunner (version #{framework.current_version} is already installed)"
    else
      Rake::Task['xulrunner:install'].invoke
    end
  end

  desc "Check to see whether XULRunner is installed"
  task 'check-install' do
    framework = platform.derivative(Xulrunner::Framework).new

    if framework.installed?
      say "XULRunner is installed"
      framework.versions.each do |version|
        if version == framework.current_version
          puts "-> #{version}"
        else
          puts "   #{version}"
        end
      end
    else
      say "XULRunner is not installed"
    end
  end
end
