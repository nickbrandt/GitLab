class AddFilterToLdapGroupLinks < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    add_column(:ldap_group_links, :filter, :string)
  end
end
