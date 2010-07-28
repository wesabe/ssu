require 'singleton'

def config
  BuildConfiguration.instance
end

class BuildConfiguration
  include Singleton
  
  def appname
    config['App']['Name']
  end
  
  def vendor
    config['App']['Vendor']
  end
  
  def profile
    path = 
      if platform.macosx?
        "~/Library/Application Support/#{appname}/Profiles/*.default"
      elsif platform.linux?
        "~/.#{vendor.downcase}/#{appname.downcase}/*.default"
      end
    Dir.glob(File.expand_path(path)).first
  end

  def log_file
    profile && "#{profile}/wuff_log.txt"
  end
  
  def config
    return @config if @config

    contents = File.read("application/application.ini")
    @config = {}
    current_section = nil
    contents.each_line do |line|
      case line
      when /^;/, /^\s*$/
        # comment, blank
      when /^\[(.*)\]/
        current_section = @config[$1] = {}
      when /^(\w+)=(.*)$/
        current_section[$1] = $2.chomp
      end
    end
    @config
  end
  
  def [](key)
    config[key]
  end
end
