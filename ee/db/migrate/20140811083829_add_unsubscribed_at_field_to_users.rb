# rubocop:disable Migration/Datetime
class AddUnsubscribedAtFieldToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :admin_email_unsubscribed_at, :datetime
  end
end
