require 'net/http'
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
      response = post '/eval', :script => '(require "io/Dir").profile.path',
                               :type => 'text/coffeescript'

      JSON.parse(response.body)['result']
    end

    def get(path)
      request :method => :get,
              :path   => path
    end

    def post(path, data=nil)
      request :method => :post,
              :path   => path,
              :body   => data
    end

    def put(path, data=nil)
      request :method => :put,
              :path   => path,
              :body   => data
    end

    def json(method, path, data=nil)
      JSON.parse(request(:method => method, :path => path, :body => data).body)
    end

    def request(options={})
      Net::HTTP.start('127.0.0.1', port) do |http|
        request = Net::HTTP.const_get(options[:method].to_s.capitalize).new options[:path]
        request['Accept'] = 'application/json'
        case options[:body]
        when String
          request.body = options[:body]
          request.content_type = options[:content_type] || 'text/plain'
        when nil
          # no body
        else
          request.body = options[:body].to_json
          request.content_type = 'application/json'
        end

        case response = http.request(request)
        when Net::HTTPSuccess
          return response
        end

        raise Error, "Invalid response: #{response.inspect}: #{response.body}"
      end
    end

    def [](action, body=nil)
      response = post '/_legacy', :action => action, :body => body

      res = JSON.parse(response.body)['response']
      case res['status']
      when 'ok'
        return res[action]
      when 'error'
        raise Error, res['error']
      end
    end

  end
end
