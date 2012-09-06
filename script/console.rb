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

  def get(path)
    request :get, path
  end

  def post(path, data=nil)
    request :post, path, data
  end

  def put(path, data=nil)
    request :put, path, data
  end

  def delete(path, data=nil)
    request :delete, path, data
  end

  def request(method, path, data=nil)
    response = Api.request :method => method, :path => path, :body => data
    case response.content_type
    when 'application/json'
      JSON.parse(response.body)
    else
      response.body
    end
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
        puts post('/eval', :script => script, :type => type, :color => $stdin.tty?)['result']
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
    else
      super
    end
  end
end

class Job
  ROOT = '/jobs'.freeze

  def self.create(data)
    new Api.json(:post, ROOT, data)['id']
  end

  def self.all
    Api.json(:get, ROOT).map do |data|
      new data['id']
    end
  end

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def resume(creds)
    Api.json :put, path, :creds => creds
  end

  def status
    Api.json :get, path
  end

  def path
    ROOT/id
  end
end

class Statement
  ROOT = '/statements'.freeze

  def self.all
    Api.json(:get, ROOT).map do |data|
      new data['id']
    end
  end

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def read
    Api.get(path).body
  end

  #EDITED BY @MDOBS
  def save
    File.open("#{@id}", 'w') {|f| f.write(Api.get(path).body) }
  end

  def path
    ROOT/id
  end
end

begin
  Api.port = ENV['PORT']
  puts "Loading xulrunner shell (port=#{Api.port}, profile=#{Api.profile})"
rescue Errno::ECONNREFUSED
  $stderr.puts "No xulrunner found running on port=#{Api.port}!"
  exit(1)
end
