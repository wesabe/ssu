require 'open-uri'
require 'hpricot'

class SSU::Generators::PlayerGenerator::FinancialInstLoader
  class DataLoadError < RuntimeError; end

  attr_reader :name, :login_url, :homepage_url
  attr_reader :fid, :username, :password

  def initialize(fid, username, password)
    @fid, @username, @password = fid, username, password
  end

  def load
    process_response(`curl -u "#{username}:#{password}" https://www.wesabe.com/financial-institutions/#{fid}.xml 2>/dev/null`)
    # http = Net::HTTP.new('www.wesabe.com', 443)
    # http.use_ssl

    # http.start do
    #   req = Net::HTTP::Get.new("/financial-institutions/#{fid}.xml")
    #   req.basic_auth(username, password)
    #   response = http.request(req)
    #   process_response(response)
    # end

    return self
  end

  def process_response(response)
    begin
      doc = Hpricot.XML(response)
      @name = element_value(doc.at("financial-inst name"))
      @login_url = element_value(doc.at("financial-inst login-url"))
      @homepage_url = element_value(doc.at("financial-inst homepage-url"))
    rescue Exception => e
      raise DataLoadError, "Failed to load FI data. Got exception: #{e.inspect}"
    end
  end

  def element_value(element)
    return element.inner_html unless !element || element.attributes['nil'] == 'true'
  end

  def self.load(fid, username, password)
    new(fid, username, password).load
  end
end
