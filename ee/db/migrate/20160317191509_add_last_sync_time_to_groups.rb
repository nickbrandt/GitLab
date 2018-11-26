# rubocop:disable all
class AddLastSyncTimeToGroups < ActiveRecord::Migration[4.2]
  def change
    add_column :namespaces, :last_ldap_sync_at, :datetime
    add_index :namespaces, :last_ldap_sync_at
  end
end
