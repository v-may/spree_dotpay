module Spree
  class OffsitePayment::Dotpay < PaymentMethod
    require 'offsite_payments'
    preference :account_id, :string
    preference :pin, :string
    # Comma separated string with ip addresses
    preference :server_ips, :string, default: ""
    preference :service_url, :string, default: OffsitePayments::Integrations::Dotpay.service_url

    def source_required?
      false
    end

    def provider_class
      OffsitePayments::Integrations::Dotpay
    end

    def service_url
      preferred_service_url
    end

    def service_for(order, options = {})
      account = preferred_account_id
      
      self.provider_class::Helper.mapping :return_url, 'url'
      self.provider_class::Helper.mapping :notify_url, 'urlc'

      service = self.provider_class::Helper.new order.number, account, options.except(:fields)
      
      service.description = order_description order
      service.control = order.number
      service.amount = payment_amount(order).to_s
      service.currency = order.currency
      
      bill_address = order.bill_address

      service.add_field(service.mappings[:customer][:firstname], bill_address.firstname)
      service.add_field(service.mappings[:customer][:lastname], bill_address.lastname)
      service.add_field(service.mappings[:customer][:email], order.email)

      service.billing_address({
        street: bill_address.address1,
        street_n1: bill_address.address2,
        city: bill_address.city,
        postcode: bill_address.zipcode,
        country: bill_address.country.iso3,
        phone: bill_address.phone
      })

      # Use fields key in the options to override default fields values
      if options[:fields].present?
        options[:fields].each do |k, v|
          mapping = service.mappings[k]
          service.add_field(mapping, v)
        end
      end

      service
    end

    def service_url_for(order, options = {})
      service = service_for order, options
      service_url + '?' + service.fields.to_query
    end

    def notification(post, options = {})
      options = {pin: preferred_pin}.merge options
      notify = provider_class.notification post, options
      notify.production_ips = preferred_server_ips ? preferred_server_ips.split : []
      notify
    end

    def order_number_from(notification)
      notification.control
    end

    private
      def order_description(order)
        "#{Spree::Store.current.name} #{Spree.t(:order).downcase} ##{order.number}"
      end

      def payment_amount(order)
        pm = order.payments.checkout.find { |p| p.payment_method.is_a?(Spree::OffsitePayment::Dotpay) }
        return pm.amount if pm.present?

        order.outstanding_balance
      end
  end
end
