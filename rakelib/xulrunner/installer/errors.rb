module Xulrunner
  class InstallError < RuntimeError
  end

  class DownloadError < InstallError
    def initialize(url, message)
      @url = url
      @message = message
    end

    def message
      "Unable to download #{@url}: #{@message}"
    end
  end
end
