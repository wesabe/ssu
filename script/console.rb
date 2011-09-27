require 'readline'
require 'socket'
require 'json'

class String
  def /(last)
    File.join(self, last)
  end
end

SCRIPT_HISTORY = Hash.new {|h,k| h[k] = [] }

require File.dirname(__FILE__)/'api'

self.instance_eval do
  def fis
    Dir.glob(credpath/'*').map do |fi|
      File.basename(fi)
    end
  end

  def js
    start_script_repl :js, 'text/javascript'
  end

  def coffee
    start_script_repl :coffee, 'text/coffeescript'
  end

  def start_script_repl(command, type)
    # this bit of insanity is needed since HISTORY is not an Array
    history = IRB::ReadlineInputMethod::HISTORY
    script_history = SCRIPT_HISTORY[command]
    ruby_history = []

    ruby_history << history.shift until history.empty?
    history << script_history.shift until script_history.empty?

    puts "=> entering #{command} mode"
    loop do
      script = Readline.readline "#{command}> "
      break if script.nil? || %w[exit quit].include?(script)
      next if script.empty?

      history << script
      begin
        puts Api['eval', {:script => script, :type => type, :color => $stdin.tty?}]
      rescue Api::Error => e
        puts e
      rescue => e
        puts "error while communicating with xulrunner: #{e.message}"
      end
    end
    puts
    result = Object.new
    def result.inspect; 'back to ruby mode'; end
    result
  ensure
    # don't record the "js" call
    ruby_history -= [command.to_s]

    script_history << history.shift until history.empty?
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
  instance_methods.each { |m| undef_method m unless m =~ /^(__|object_id)/ }

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
