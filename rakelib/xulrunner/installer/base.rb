module Xulrunner
  class Installer
    HOST = "releases.mozilla.org"
    RELEASE_PATH = "pub/mozilla.org/xulrunner/releases"

    def self.install(version)
      new.install(version)
    end

    def install(version)
      file = platform_package_path(version)
      package_path = download_if_necessary(file, File.basename(file))
      platform_install(package_path)
      File.delete(package_path)
      return true
    end

    def download_if_necessary(file, target)
      download(file, target) unless File.exist?(target)
      return target
    end

    def download(file, target)
      url = url_for(file)

      Shell "curl", '-o' ,target, url do |status, output|
        raise DownloadError.new(url, output)
      end

      return target
    end

    def url_for(file)
      "http://#{HOST}/#{RELEASE_PATH}/#{file}"
    end

    def platform_package_path(version)
      "#{version}/runtimes/#{file_for_platform(version)}"
    end

    def platform_install(package_path)
      raise NotImplementedError
    end
  end
end
