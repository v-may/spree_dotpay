class CreateSpreeDotpayNotices < ActiveRecord::Migration
  def change
    create_table :spree_dotpay_notices do |t|
      t.string :transaction_id
      t.string :transaction_status
      t.integer :order_id

      t.timestamps
    end

    add_index :spree_dotpay_notices, :transaction_id
    add_index :spree_dotpay_notices, :order_id
  end
end
