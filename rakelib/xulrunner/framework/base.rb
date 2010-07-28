module Xulrunner
  class Framework
    def installed?
      not current_version.nil?
    end

    def current_version
      raise NotImplementedError
    end

    def versions
      raise NotImplementedError
    end

    def framework_paths
      raise NotImplementedError
    end
  end
end
