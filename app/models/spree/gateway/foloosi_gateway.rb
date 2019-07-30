module Spree
  class Gateway::FoloosiGateway < Gateway
    TEST_VISA = ['4111111111111111', '4012888888881881', '4222222222222']
    TEST_MC   = ['5500000000000004', '5555555555554444', '5105105105105100', '2223000010309703']
    TEST_AMEX = ['378282246310005', '371449635398431', '378734493671000', '340000000000009']
    TEST_DISC = ['6011000000000004', '6011111111111117', '6011000990139424']

    VALID_CCS = ['1', TEST_VISA, TEST_MC, TEST_AMEX, TEST_DISC].flatten
    URL = "https://secure.telr.com/gateway/order.json"

    attr_accessor :test
    preference :merchant_id, :string
    preference :api_key, :string

    def provider_class
      self.class
    end

    def method_type
      'telr'
    end

    def supports?(source)
      true
    end

    def purchase(_money, telr_checkout, _options = {})

      payload = {
        method: 'check',
        store: preferred_merchant_id,
        authkey: preferred_api_key,
        order: {
          ref: telr_checkout.ref
        }
      }

      errors = []
      ret = nil

      begin
        ret = Class.new do
          def success?; true; end
          def authorization; nil; end
        end.new
      rescue => e
        errors << e.backtrace.join("\n\t")
        ret = ::ResponseClass.new '-99', 'ErrorCode:1 -> unknown error occured, please contact support', false
      end

      # telr_checkout.update_column(:telr_errors, errors)
      ret

    end

    def void(_response_code, _credit_card, _options = {})
      ActiveMerchant::Billing::Response.new(true, 'Bogus Gateway: Forced success', {}, test: true, authorization: '12345')
    end

    def cancel(_response_code)
      ActiveMerchant::Billing::Response.new(true, 'Bogus Gateway: Forced success', {}, test: true, authorization: '12345')
    end

    def actions
      %w(capture void credit)
    end
  end
end

class ResponseClass
  def initialize(error_code,error_msg, success)
    @error_code=error_code
    @error_msg=error_msg
    @success = success
  end

  def success?
   @success
  end

  def to_s
    @error_code.to_s + ':' + @error_msg.to_s
  end
end
