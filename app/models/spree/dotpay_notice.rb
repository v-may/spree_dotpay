class Spree::DotpayNotice < Spree::Base
  belongs_to :order, class_name: 'Spree::Order'

  validates :transaction_id, uniqueness: { scope: :transaction_status }

  def processed?
    order_id.present?
  end
end
