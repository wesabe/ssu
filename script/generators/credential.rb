module SSU
  module Generators
    class CredentialGenerator < Templater::Generator
      desc %{Credential file for a financial institution (username/password).\n\nExample: script/generate credential us-000238 bofa}

      def self.source_root
        File.join(File.dirname(__FILE__), 'credential', 'templates')
      end

      first_argument :fid, :required => true
      second_argument :name, :required => true

      template :credential do |t|
        t.source = "credential.js.erb"
        t.destination = "credentials/#{name}"
      end
    end
  end
end
