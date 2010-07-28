require 'socket'
require 'json'

class Api
  class Error < RuntimeError; end

  class <<self
    def port
      @port
    end

    def port=(port)
      @port = port.to_i
    end

    def profile
      self['eval', {:script => 'wesabe.io.dir.profile.path'}]
    end

    def [](action, body=nil)
      begin
        sock = TCPSocket.new('127.0.0.1', port)
        req = {:action => action, :body => body}.to_json
        sock.puts(req)
        res = JSON.parse(sock.readline)['response']
        case res['status']
        when 'ok'
          res[action]
        when 'error'
          raise Error, res['error']
        else
          raise Error, "Invalid response: #{res.inspect}"
        end
      rescue Errno::ECONNREFUSED
        raise Errno::ECONNREFUSED, "Couldn't connect to the server. Are you sure it's running?"
      end
    end
  end
end
