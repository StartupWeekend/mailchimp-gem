module Mailchimp
  class API
    include HTTParty
    format :plain
    default_timeout 30

    attr_accessor :api_key, :timeout, :throws_exceptions

    def initialize(api_key = nil, extra_params = {})
      @api_key = api_key || ENV['MAILCHIMP_API_KEY'] || self.class.api_key
      @default_params = {:apikey => @api_key}.merge(extra_params)
      @basic_auth = basic_auth
      @throws_exceptions = false
    end

    def api_key=(value)
      @api_key = value
      @default_params = @default_params.merge({:apikey => @api_key})
    end

    def base_api_url
      "https://#{dc_from_api_key}api.mailchimp.com/3.0/"
    end

    def basic_auth
      { :username => 'apikey', :password => @api_key }
    end

    def valid_api_key?(*args)
      %q{"Everything's Chimpy!"} == call("#{base_api_url}ping")
    end

    def templates(options)
      self.class.get(base_api_url + "templates", options)
    end

    def lists(*args)
      self.class.get(base_api_url + "lists", :basic_auth => basic_auth)
    end

    def list(*args)
      self.class.get(base_api_url + "lists/#{args.first.first[:filters][:list_id]}", :basic_auth => basic_auth)
    end

    def search_members(member)
      self.class.get(base_api_url + "search-members?query=#{member}", :basic_auth => basic_auth)
    end

    protected

    def dc_from_api_key
      (@api_key.nil? || @api_key.length == 0 || @api_key !~ /-/) ? '' : "#{@api_key.split("-").last}."
    end
  end
end
