%w[macosx? linux? windows?].each do |m|
  instance_eval %{
    def #{m}; platform.#{m}; end
  }
end

require 'singleton'

module BuildPlatform
  extend self

  attr_accessor :toplevel

  def name
    RUBY_PLATFORM
  end

  def shortname
    if macosx?
      'macosx'
    elsif linux?
      'linux'
    elsif windows?
      'windows'
    end
  end

  def derivative(klass)
    parts = klass.name.split('::')
    parts.last.sub!(/^/, class_prefix)
    derivative = parts.inject(Object) do |const, name|
      const.const_get(name)
    end
    if derivative.nil?
      raise ArgumentError, "Unable to find a platform-specific derivative of #{klass}. You need to implement #{parts.join('::')}"
    else
      return derivative
    end
  end

  def class_prefix
    if macosx?
      'Mac'
    elsif linux?
      'Linux'
    elsif windows?
      'Win'
    end
  end

  def macosx?
    name =~ /darwin/
  end

  def linux?
    name =~ /linux/
  end

  def windows?
    name =~ /(win|w)32$/
  end

  private

  def method_missing(method, *args, &block)
    call_toplevel_method(method, *args, &block)
  end

  def call_toplevel_method(method, *args, &block)
    toplevel.send(platform_method_name(method), *args, &block)
  end

  def platform_method_name(method)
    "#{method}_#{shortname}"
  end
end

BuildPlatform.toplevel = self

def platform
  BuildPlatform
end
