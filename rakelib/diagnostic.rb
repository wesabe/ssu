require 'script/api'

def diagnostic
  server_thread = Thread.new { run_diagnostic_server }

  begin
    obtain_server_connection
  rescue Exception => e
    abort "failed to connect to xulrunner process: #{e.message}"
  end

  begin
    test_external_internet_connection
  rescue Exception => e
    abort "xulrunner failed to reach the external internet: #{e.message}"
  end

  $stderr.puts "Everything seems to be working. Good luck, we're all counting on you."
end

alias diagnostic_macosx diagnostic
alias diagnostic_linux diagnostic
alias diagnostic_windows diagnostic

def run_diagnostic_server
  $stderr.puts "Starting the xulrunner process"
  begin
    platform.server
    raise "Got exit status from xulrunner: #{$?.exitstatus}" unless $?.exitstatus.zero?
  rescue Exception => e
    abort "xulrunner process failed to start: #{e.message}"
  end
end

def obtain_server_connection
  $stderr.puts "Connecting to the xulrunner process"
  tries_left = 10
  Api.port = 5000
  try do
    Api.profile
    at_exit { Api['xul.quit'] }
  end
end

def test_external_internet_connection
  assert_url_reachable("http://www.google.com/")
end

def assert_url_reachable(url)
  $stderr.puts "Testing communicating with #{url}"
  Api['eval', {:script => %{$diag = null; wesabe.io.get("#{url}", null, null, function(response){ $diag = #{$$} })}}]
  try do
    raise "Couldn't connect to #{url}" if Api['eval', {:script => '$diag'}].to_i != $$
  end
end

def try(tries_left=10)
  begin
    yield
  rescue Exception => e
    if tries_left.zero?
      raise e
    else
      $stderr.print '.'
      sleep 1
      tries_left -= 1
      retry
    end
  ensure
    $stderr.puts
  end
end
