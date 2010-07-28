module Xulrunner
  class MacFramework < Framework
    def current_version
      framework_paths.each do |path|
        link = File.join(path, 'Versions', 'Current')
        if File.exist?(link)
          version = File.readlink(link)
          return version
        end
      end

      return nil
    end

    def versions
      framework_paths.map do |path|
        Dir.entries(File.join(path, 'Versions')).grep(/^\d[\d\.]+/)
      end.flatten.uniq
    end

    def framework_paths
      base = "/Library/Frameworks/XUL.framework"
      ["~#{base}", base].select {|path| File.directory?(File.expand_path(path))}
    end
  end
end
