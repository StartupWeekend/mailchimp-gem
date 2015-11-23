module Mailchimp
  class MandrillDeliveryHandler
    attr_accessor :settings

    def initialize(options = {})
      self.settings = {:track_opens => true, :track_clicks => true, :from_name => 'Mandrill Email Delivery Handler'}.merge(options)
    end

    def deliver!(message)
      api_key = message.header['api-key'].blank? ? settings[:api_key] : message.header['api-key']
      
      message_payload = get_message_payload(message)
      self.settings[:return_response] = Mailchimp::Mandrill.new(api_key).messages_send(message_payload)
    end
    
    private
    
    def get_content_for(message, format)
      mime_types = {
        :html => "text/html",
        :text => "text/plain"
      }
      
      content = message.send(:"#{format.to_s}_part")
      content ||= message.body if message.mime_type == mime_types[format]
      content
    end

    def get_message_payload(message)
      message_payload = {
        :track_opens => settings[:track_opens],
        :track_clicks => settings[:track_clicks],
        :message => {
          :subject => message.subject,
          :from_name => message.header['from-name'].blank? ? settings[:from_name] : message.header['from-name'],
          :from_email => message.from.first,
          :to => message.to.map {|email| { :email => email, :name => email } },
          :headers => {'Reply-To' => message.reply_to.nil? ? nil : message.reply_to }
        }
      }
      message_payload[:message][:bcc_address] = message.bcc.first if message.bcc && !message.bcc.empty?
      [:html, :text].each do |format|
        content = get_content_for(message, format)
        message_payload[:message][format] = content if content
      end

      message_payload[:tags] = settings[:tags] if settings[:tags]
      message_payload
    end
  end
end

if defined?(ActionMailer)
  ActionMailer::Base.add_delivery_method(:mailchimp_mandrill, Mailchimp::MandrillDeliveryHandler)
end

