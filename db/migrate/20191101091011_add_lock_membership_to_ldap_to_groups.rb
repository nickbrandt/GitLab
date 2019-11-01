# frozen_string_literal: true

class AddLockMembershipToLdapToGroups < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:namespaces, :lock_membership_to_ldap, :boolean, default: true)
  end

  def down
    remove_column :namespaces, :lock_membership_to_ldap
  end
end
