require 'open3'
require 'readline'
require 'cgi'


desc "Validate the source files."
task :validate => %w[validate:javascript validate:xpath]

module Wesabe
  class ScriptError
    include Comparable

    attr_accessor :message, :lineno, :file

    def initialize(file, lineno, message)
      self.file, self.lineno, self.message = file, lineno, message
    end

    def lineno=(lineno)
      @lineno = lineno.to_i
    end

    def file=(file)
      @file = File.expand_path(file)
    end

    def each_context_line
      first = [lineno-2, 1].max
      last  = [first+4, lines.size].min

      (first..last).each do |ln|
        yield ln, lines[ln-1]
      end
    end

    def lines
      @lines ||= content.to_a
    end

    def content
      @content ||= File.read(file)
    end

    def <=>(other)
      self.lineno <=> other.lineno
    end
  end
end

def present_script_errors(errors)
  errors_by_file = begin
    result = Hash.new {|hash, key| hash[key] = []}
    errors.each {|error| result[error.file] << error}
    result.each {|_,v| v.sort!}
  end

  errors_by_file.each do |file, errors|
    puts
    puts "\e[1;36m#{File.basename(file)}\e[0;36m in #{File.dirname(file)}\e[0m"
    puts

    errors.each_with_index do |error, i|
      puts "#{i+1}. \e[0;31m#{error.message}\e[0m"

      error.each_context_line do |lineno,line|
        print "\e[1m" if lineno == error.lineno
        puts "   #{lineno}\t#{line}"
        print "\e[0m" if lineno == error.lineno
      end

      puts
    end

    index = Readline.readline("go to (1..#{errors.size})> ").to_i
    if (1..errors.size).include?(index)
      error = errors[index-1]
      `open "txmt://open?url=#{CGI.escape("file://#{error.file}")}&line=#{error.lineno}"`
    end
  end
end

namespace :validate do
  task :javascript do
    Dir['application/**/*.js'].each do |file|
      out = `jsl -process "#{file}"`
      if $?.exitstatus == 3 # javascript errors
        base = Dir.pwd
        errors = out.scan(%r{^(.*#{Regexp.escape(file)})\((\d+)\): (.*)$\s*(.*)$})
        errors.map! do |error|
          Wesabe::ScriptError.new(file, error[1], error[2])
        end

        present_script_errors(errors)
      end
    end
  end

  task :xpath do
    xpaths = []
    errors = []

    Dir['application/chrome/content/wesabe/fi-scripts/**/*.js'].each do |path|
      contents = File.read(path).to_a
      elements_start_index = nil

      contents.each_with_index do |line, i|
        if line =~ /^\s*elements:\s*\{\s*$/
          elements_start_index = i
          break
        end
      end

      if elements_start_index
        contents[elements_start_index..-1].each_with_index do |line,lineno|
          xpaths << [$1.gsub("\\'", "'"), path, elements_start_index + lineno + 1] if line =~ /^\s*(?:[a-zA-Z0-9]+:\s*)?'((?:[^']|\')+)',?\s*\]?\s*,?\s*$/
        end
      end
    end

    Open3.popen3("java -classpath rakelib XPathValidator") do |stdin, stdout, stderr|
      stdin.puts(xpaths.map{|line, path, lineno| line}.join("\n"))
      stdin.close

      begin
        xpaths.each do |line, path, lineno|
          message = stdout.gets
          message &&= message.chomp
          next if message.nil? || message.empty?
          errors << Wesabe::ScriptError.new(path, lineno, message)
          puts "#{path}:#{lineno}: #{line}: #{message}"
        end
      rescue EOFError
        $stderr.puts "Unexpected end of file reached while reading from XPathValidator"
      end
    end

    present_script_errors(errors)
  end
end
