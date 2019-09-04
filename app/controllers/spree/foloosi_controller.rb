

module Spree
  class FoloosiController < StoreController

    def express

      @order = current_order || raise(ActiveRecord::RecordNotFound)

      begin
        result = hit
        order  = @order

        ref_token       = result.parsed_response.dig("data","reference_token")
        payment_qr_data = result.parsed_response.dig("data","payment_qr_data")
        payment_qr_url  = result.parsed_response.dig("data","payment_qr_url")
        error =  result.parsed_response.dig("message") || []

        if(ref_token.blank?)
          flash[:error] = error
          render json: {errors: error}
        else

          render json: {ref_token: ref_token, errors: [], merchant_key: payment_method.try(:preferred_merchant_id) }

          order.payments.create!({
            source: Spree::FoloosiCheckout.create({
              ref: ref_token,
            }),
            amount: order.total,
            payment_method: payment_method
          })

          # redirect_to checkout_state_path(state: :payment,telr_url:url, pmi: params['payment_method_id'] )
        end


        
      rescue => e
        flash[:error] = Spree.t('flash.connection_failed', scope: 'telr')
        # redirect_to checkout_state_path(:payment)
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
          :body => payload,
          :headers => { 
                        'secret_key'   => payment_method.try(:preferred_merchant_id)
                      } 
      )
    end

    def transaction_updator
      payment_trans_id    = params[:trans_id]
      follosi_payment_obj = current_order.payments.last

      if follosi_payment_obj.present?
        follosi_payment_obj.source.update(transaction_id: payment_trans_id )
        render json: {ref_token: follosi_payment_obj.source.ref, merchant_key: payment_method.try(:preferred_merchant_id), errors: []}
      else
        render json: {errors: ["No payment source found"]}
      end
    end


    private
    def payment_method
      Spree::PaymentMethod.find(params[:payment_method_id])
    end

    def payload

      {
        redirect_url: foloosi_v2_url,
        transaction_amount: @order.total,
        currency: current_currency.present? ? current_currency : "AED"
      }

    end

    def completion_route(order)
      order_path(order)
    end
  end
end



