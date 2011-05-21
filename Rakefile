task :default => :bootstrap
task :build => :bootstrap

desc "Bootstrap the application"
task :bootstrap do
  exec "./bootstrap"
end

def installed?(binary)
  system %{which -s "#{binary}" 2>/dev/null}
  return $?.success?
end

desc "Run the specs"
task :spec do
  if not installed?('jasmine-node')
    $stderr.puts "~ You don't seem to have jasmine-node installed!"
    $stderr.puts "~ Install it with: npm install jasmine-node"

    if not installed?('npm')
      $stderr.puts "~"
      $stderr.puts "~ For help installing npm, visit http://npmjs.org/"
    end
  else
    system %{jasmine-node --coffee spec}
    exit $?.exitstatus
  end
end
