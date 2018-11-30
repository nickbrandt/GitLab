class AddSecondaryExternUidToIdentities < ActiveRecord::Migration[4.2]
  def change
    add_column :identities, :secondary_extern_uid, :string
  end
end
