# frozen_string_literal: true

class AddIndexOnUserIdTypeSourceTypeLdapAndCreatedAtToMembers < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_members_on_user_id_type_source_type_ldap_and_created_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :members, [:user_id, :type, :source_type, :ldap, :created_at], where: "ldap = TRUE AND type = 'GroupMember' AND source_type = 'Namespace'", name: INDEX_NAME
  end

  def down
    remove_concurrent_index :members, INDEX_NAME
  end
end
