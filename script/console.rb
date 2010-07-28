require 'rubygems'
require 'readline'
require 'socket'
require 'json'

class String
  def /(last)
    File.join(self, last)
  end
end

JAVASCRIPT_HISTORY = []

require File.dirname(__FILE__)/'api'

self.instance_eval do
  def fis
    Dir.glob(credpath/'*').map {|fi| File.basename(fi)}
  end

  def js
    # this bit of insanity is needed since HISTORY is not an Array
    history = IRB::ReadlineInputMethod::HISTORY
    js_history = JAVASCRIPT_HISTORY
    ruby_history = []

    ruby_history << history.shift until history.empty?
    history << js_history.shift until js_history.empty?

    puts '=> entering javascript mode'
    loop do
      script = Readline.readline 'js> '
      break if script.nil? || %w[exit quit].include?(script)
      next if script.empty?

      history << script
      begin
        puts Api['eval', {:script => script}]
      rescue Api::Error => e
        puts e
      rescue => e
        puts "error while communicating with xulrunner: #{e.message}"
      end
    end
    puts
    js = Object.new
    def js.inspect; 'back to ruby mode'; end
    js
  ensure
    # don't record the "js" call
    ruby_history -= ['js']

    js_history << history.shift until history.empty?
    history << ruby_history.shift until ruby_history.empty?
  end

  def credpath
    oldpwd = Dir.pwd
    begin
      loop do
        if File.directory?('credentials')
          return File.expand_path('credentials')
        elsif File.expand_path('.') == '/' # at the root
          break
        end

        Dir.chdir('..')
      end

      # fall back to the old location
      return "/tmp/credentials"
    ensure
      Dir.chdir(oldpwd)
    end
  end

  def method_missing(method, *args, &block)
    method = method.to_s
    if fis.include?(method)
      JSON.parse(File.read(credpath/method))
    elsif args.empty?
      ApiMethodChainer.new(method)
    else
      super
    end
  end
end

class ApiMethodChainer
  instance_methods.each { |m| undef_method m unless m =~ /^__/ }

  def initialize(first=nil)
    parts << first if first
  end

  def parts
    @parts ||= []
  end

  def method_missing(method, *args, &block)
    parts << method
    Api[parts.join('.'), *args]
  end
end

begin
  Api.port = ENV['PORT']
  puts "Loading xulrunner shell (port=#{Api.port}, profile=#{Api.profile})"
rescue Errno::ECONNREFUSED
  $stderr.puts "No xulrunner found running on port=#{Api.port}!"
  exit(1)
end
