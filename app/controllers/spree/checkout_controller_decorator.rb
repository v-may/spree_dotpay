Spree::CheckoutController.class_eval do

  before_action :pay_via_dotpay, only: :update

  private
    def pay_via_dotpay
      order = current_order
      return unless order && ["payment", "confirm"].include?(order.state)
      return if order.paid? || !order.payment_required?

      if order.payment?
        return if order.has_step?("confirm")
        payment_method = Spree::PaymentMethod.find(params[:order][:payments_attributes].first[:payment_method_id])
      else
        payment = order.payments.checkout.first
        return unless payment
        payment_method = payment.payment_method
      end
      return unless payment_method.kind_of?(Spree::OffsitePayment::Dotpay)

      redirect_to offsite_payment_dotpay_path and return false
    end

end