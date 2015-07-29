module Spree
  class OffsitePayment::DotpayController < StoreController
    skip_before_filter :verify_authenticity_token, :only => [:notify, :done]

    def purchase
      order = current_order
      unless order && (order.confirm? || order.payment?) && !order.paid?
        flash.notice = Spree.t :order_not_found_for_payment
        redirect_to cart_path and return
      end

      unless payment_method
        flash.notice = Spree.t :payment_method_not_supported
        redirect_to cart_path and return
      end

      options = {
        notify_url: offsite_payment_notify_dotpay_url,
        return_url: offsite_payment_return_dotpay_url + "?" + {order_number: order.number}.to_query,
        fields: {
          type: 0, 
          lang: I18n.locale.to_s
        }
      }
      redirect_to payment_method.service_url_for(order, options)
    end

    def notify
      notice = payment_method.notification request.raw_post
      if notice.valid_sender?(request.remote_ip) && notice.acknowledge
        if notice.complete?
          order_number = payment_method.order_number_from notice 
          order = Spree::Order.find_by_number order_number
          payment = order.payments.create!(
                                           :amount => notice.gross, 
                                           :payment_method_id => payment_method.id)
          payment.complete
          order.reload
          order.next
          order.next if order.confirm?
        end

        render text: 'OK'
      else
        render text: 'FAIL'
      end
    end

    def done
      order = Spree::Order.find_by_number(params[:order_number])
      unless order
        flash.notice = Spree.t :order_not_found
        redirect_to root_path and return
      end

      if order.complete?
        flash[:notice] = Spree.t(:order_processed_successfully)
        flash['order_completed'] = true
        redirect_to order_path(order)
      else
        flash[:error] = Spree.t :failed_payment_attempts
        redirect_to checkout_state_path(order.state)
      end
    end

    private
      def payment_method
        @payment_method ||= Spree::Order.new.available_payment_methods.select {|m| m.kind_of? Spree::OffsitePayment::Dotpay}.first
      end
  end
end