require 'yaml'
require 'readline'

SSU_CONFIG_DIR = '/etc/ssu'
SSU_CONFIG_FILES = {
  :xulrunner => 'xulrunner.js',
}

class Object
  def blank?
    false
  end
end

class NilClass
  def blank?
    true
  end
end

class String
  def blank?
    self =~ /\A\s*\Z/
  end
end

class Array
  def blank?
    empty?
  end
end

def config_path(file=nil)
  case file
  when nil
    SSU_CONFIG_DIR
  when Symbol
    config_path SSU_CONFIG_FILES[file]
  when String
    File.join(SSU_CONFIG_DIR, file)
  end
end

def readline_with_default(prompt, default)
  case default
  when TrueClass
    prompt = "#{prompt} [nY]"
  when FalseClass
    prompt = "#{prompt} [yN]"
  else
    prompt = "#{prompt} [#{default}]" unless default.blank?
  end

  result = Readline.readline("#{prompt} ")
  return default if result.blank?

  case default
  when TrueClass, FalseClass
    result =~ /y/i
  when Fixnum
    result.to_i
  else
    result
  end
end

namespace :config do
  task 'base' do
    sh("sudo mkdir -p #{SSU_CONFIG_DIR}") unless File.directory?(SSU_CONFIG_DIR)
    sh("sudo chown -R #{ENV['USER']} #{SSU_CONFIG_DIR}") unless File.owned?(SSU_CONFIG_DIR)
  end

  desc "Reset all the configuration for this application"
  task 'reset' do
    Dir[config_path('*')].each do |path|
      sh("mv #{path} #{path}.backup")
    end
  end

  desc "Restore configuration from backup"
  task 'restore' do
    Dir[config_path('*.backup')].each do |path|
      sh("mv #{path} #{path.sub(/\.backup$/, '')}")
    end
  end

  desc "Guides you through configuring xulrunner"
  task 'xulrunner' => %w[config:base] do
    puts "** Configuring XulRunner"

    path  = config_path(:xulrunner)
    prefs = {}

    if File.readable?(path)
      prefs = File.read(path).to_a

      prefs = prefs.inject({}) do |m, pref|
        m[$1] = eval($2) if pref =~ /^pref\(['"](.+?)['"],\s*(.+)\)/
        m
      end
    end

    http, http_port, type = 'network.proxy.http', 'network.proxy.http_port', 'network.proxy.type'
    ssl, ssl_port = 'network.proxy.ssl', 'network.proxy.ssl_port'

    if readline_with_default("Should xulrunner use a manual proxy?", !prefs[http].blank?)
      prefs[http] = readline_with_default("What HTTP proxy host should xulrunner use?", prefs[http])
      prefs[http_port] = readline_with_default("What HTTP proxy port should xulrunner use?", prefs[http_port]).to_i
      prefs[ssl] = prefs[http]
      prefs[ssl_port] = prefs[http_port]
      prefs.delete(http_port) if prefs[http_port] == 0
      prefs[type] ||= 1 if prefs[http]
    else
      prefs.delete(http)
      prefs.delete(http_port)
      prefs.delete(ssl)
      prefs.delete(ssl_port)
      prefs.delete(type) if prefs[type] == 1
    end

    level = 'wesabe.logger.level'
    prefs[level] = 'debug' if prefs[level].blank?
    prefs[level] = readline_with_default("What logger level should the xulrunner use?", prefs[level])

    puts "Writing xulrunning configuration to: #{ path }"
    File.open(path, 'w') do |config|
      config.puts "# Mozilla Preference File"
      config.puts "// written by #{__FILE__}"
      prefs.keys.sort.each do |key|
        config.puts %{pref(#{key.inspect}, #{prefs[key].inspect});} unless prefs[key].blank?
      end
    end
  end
end

desc "Guides you through configuring the application"
task :config => %w[config:xulrunner]
