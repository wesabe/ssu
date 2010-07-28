module SSU
  module Generators
    class PlayerGenerator < Templater::Generator
      desc %{Script to download OFX statements from a Financial Institution.\n\nUsage: script/generate player wesabe-id [fi-name] [fi-login-url]\n\nExample: script/generate player us-123456}

      def self.source_root
        File.join(File.dirname(__FILE__), 'player', 'templates')
      end

      first_argument :fid, :required => true
      second_argument :org, :required => false
      third_argument :login_url, :required => false

      def org
        get_argument(1) || loaded_org || 'FI NAME HERE'
      end

      def login_url
        get_argument(2) || loaded_login_url || 'http://www.google.com/'
      end

      def loaded_org
        with_fi { |info| info.name }
      end

      def loaded_login_url
        with_fi { |info| info.login_url || info.homepage_url }
      end

      def with_fi
        case @fi
        when nil # not loaded yet
          puts "You only gave the Wesabe ID of the financial institution (#{fid})."
          print "Do you want to load the rest of it? [Yn] "
          case $stdin.gets
          when nil, /^\s+$/, /^y$/i
            load_fi_info
            return yield(@fi)
          else
            @fi = false
          end
        when false # declined to load data
          return nil
        else # already loaded
          return yield(@fi)
        end
      end

      def load_fi_info
        require File.join(File.dirname(__FILE__), "player", "financial_inst_loader")
        @fi = FinancialInstLoader.load(
          fid,
          readline("Wesabe username: "),
          readline("Wesabe password: ", true))
      end

      def readline(prompt=nil, password=false)
        begin
          require 'readline'
          system "stty -echo" if password
          Readline.readline(prompt)
        rescue LoadError
          print prompt if prompt
          $stdin.gets
        ensure
          if password
            system "stty echo"
            puts
          end
        end
      end

      template :main do |t|
        t.source = "main.js.erb"
        t.destination = "application/chrome/content/wesabe/fi-scripts/#{fid}.js"
      end

      template :login do |t|
        t.source = "login.js.erb"
        t.destination = "application/chrome/content/wesabe/fi-scripts/#{fid}/login.js"
      end

      template :accounts do |t|
        t.source = "accounts.js.erb"
        t.destination = "application/chrome/content/wesabe/fi-scripts/#{fid}/accounts.js"
      end
    end
  end
end
