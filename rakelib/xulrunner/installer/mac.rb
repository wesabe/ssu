module Xulrunner
  class MacInstaller < Installer
    def file_for_platform(version)
      "xulrunner-#{version}.en-US.mac-pkg.dmg"
    end

    def platform_install(image_path)
      ensure_installer_mounted(image_path)
      install_package(image_path)
      unmount_installer
      return true
    end

    def ensure_installer_mounted(image_path)
      mount_installer(image_path) unless installer_mounted?
      raise InstallError, "unable to mount #{image_path} at #{installer_mountpoint}" unless installer_mounted?
    end

    def installer_mounted?
      File.exist?(installer_mountpoint)
    end

    def mount_installer(image_path)
      Shell "hdiutil attach", '-mountpoint', installer_mountpoint, image_path do |status, output|
        raise InstallError, output
      end
    end

    def installer_mountpoint
      "/Volumes/XULRunnerFramework"
    end

    def install_package(image_path)
      Shell %{sudo installer}, '-package', full_package_path(image_path), '-target', '/' do |status, output|
        raise InstallError, output
      end
    end

    def full_package_path(image_path)
      "/Volumes/XULRunnerFramework/#{package_path(image_path)}"
    end

    def package_path(image_path)
      image_path.sub(/-pkg\.dmg$/, '.pkg')
    end

    def unmount_installer
      Shell %{hdiutil detach}, installer_mountpoint do |status, output|
        raise InstallError, output
      end
    end
  end
end
