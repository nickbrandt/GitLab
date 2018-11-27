# rubocop:disable all
class AddGroupMembershipLock < ActiveRecord::Migration[4.2]
  def change
    add_column :namespaces, :membership_lock, :boolean, default: false
  end
end
