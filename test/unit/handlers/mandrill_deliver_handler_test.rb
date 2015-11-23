require 'test_helper'
require File.join('./lib/mailchimp','handlers', 'mandrill_delivery_handler')

class MandrillDeliveryHandlerTest < Test::Unit::TestCase
  context "when delivering a Mail::Message to the Mandrill API" do
    setup do
      @mandrill_delivery_handler = Mailchimp::MandrillDeliveryHandler.new(:from_name => "Foo Bar")
      @fake_mandrill_api_response = [{"email"=>"foo@bar.com", "status"=>"sent"}]
      
      FakeWeb.register_uri(
      :post,
      'http://mandrillapp.com/api/1.0/messages/send',
      body: @fake_mandrill_api_response.to_json
    )
    end
    
    should "deliver successfully" do
      message = mock_mail_message
      response = @mandrill_delivery_handler.deliver!(message)
      assert_equal @fake_mandrill_api_response, response 
    end

    should "store the api response in the settings[:return_response] hash key" do
      message = mock_mail_message
      response = @mandrill_delivery_handler.deliver!(message)
      assert_equal @fake_mandrill_api_response, @mandrill_delivery_handler.settings[:return_response]
    end

    context "for the mandrill api payload" do
      should "build a valid Mandrill API payload" do
        message = mock_mail_message
        @mandrill_delivery_handler.deliver!(message)
        message_payload = @mandrill_delivery_handler.send(:get_message_payload, message)

        assert_equal true, message_payload[:track_opens]
        assert_equal true, message_payload[:track_clicks]
        assert_equal 'Subject', message_payload[:message][:subject]
        assert_equal 'foo@bar.com', message_payload[:message][:from_email]
        assert_equal 'Foo Bar', message_payload[:message][:from_name]
        assert_equal 'foo@bar.com has moved use awesome@awesomesauce.com now', message_payload[:message][:html]
        assert_equal [{email: 'foo@bar.com', name: 'foo@bar.com'}], message_payload[:message][:to]
        assert_equal({'Reply-To' => 'replyto@example.com'}, message_payload[:message][:headers])
      end

      should "handle bcc correctly" do
        message = mock_mail_message
        message.stubs(:bcc).returns(["bar@bar.com"])
        @mandrill_delivery_handler.deliver!(message)
        message_payload = @mandrill_delivery_handler.send(:get_message_payload, message)
        assert_equal 'bar@bar.com', message_payload[:message][:bcc_address]
      end
    end
  end
end
