module Mailchimp
  class APIError < RuntimeError
    attr_accessor :error, :code
    def initialize(error,code)
      super("Error from MailChimp API: #{error} (code #{code})")
      @error = error
      @code = code
    end
  end
end