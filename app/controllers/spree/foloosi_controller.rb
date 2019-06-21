require 'httparty'

module Spree
  class FoloosiController < StoreController

    def express

      @order = current_order || raise(ActiveRecord::RecordNotFound)

      begin
        result = hit
        order  = @order

        ref   = result.parsed_response.dig("order","ref")
        url   = result.parsed_response.dig("order","url")
        error =  result.parsed_response.dig("error") || []

        if(url.blank? || ref.blank?)
          flash[:error] = Spree.t('flash.generic_error', scope: 'telr', reasons: error.map{|k,v|k.to_s+':'+v.to_s}.join(','))
          redirect_to checkout_state_path(:payment)
        else
          order.payments.create!({
            source: Spree::TelrCheckout.create({
              ref: ref,
            }),
            amount: order.total,
            payment_method: payment_method
          })
          redirect_to checkout_state_path(state: :payment,telr_url:url, pmi: params['payment_method_id'] )
        end
        
      rescue => e
        flash[:error] = Spree.t('flash.connection_failed', scope: 'telr')
        redirect_to checkout_state_path(:payment)
      end
    end

    def receiver_authorized_transactions
      order = current_order || raise(ActiveRecord::RecordNotFound)
      order.next

      if order.complete?
        flash.notice = Spree.t(:order_processed_successfully)
        flash[:order_completed] = true
        session[:order_id] = nil
        redirect_to completion_route(order)
      else
        redirect_to checkout_state_path(order.state)
      end
    end

    def receiver_decl_transactions
      order = current_order || raise(ActiveRecord::RecordNotFound)
      order.next
      flash[:error] = order.payments.failed.last.source.error_msg + " - Please try again later"
      redirect_to checkout_state_path(order.state)
    end

    def receiver_cancelled_transactions
      order = current_order || raise(ActiveRecord::RecordNotFound)
      order.next
      flash[:error] = order.payments.failed.last.source.error_msg.to_s + " - Please try again later"
      redirect_to checkout_state_path(order.state)
    end

    def hit
      ::HTTParty.post("https://foloosi.com/api/v1/api/initialize-setup", 
          :body => payload.to_json,
          :headers => { 
                        'secret_key'   => 'test_$2y$10$HH0PlTdklWUYIV-ZeSzk9uoBvAgePca-wyiz1cjgjhv.GpH..wg-S'
                      } 
      )
    end

    def iniatization_response
    end


    private
    def payment_method
      Spree::PaymentMethod.find(params[:payment_method_id])
    end

    def payload

      {
        redirect_url: "/iniatization_foloosi_response",
        transaction_amount: @order.total,
        currency: 'AED'
      }

    end

    def completion_route(order)
      order_path(order)
    end
  end
end



