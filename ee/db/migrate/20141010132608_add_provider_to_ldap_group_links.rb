class AddProviderToLdapGroupLinks < ActiveRecord::Migration[4.2]
  def change
    add_column :ldap_group_links, :provider, :string
  end
end
