class AddIndexesToRemoteMirror < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :remote_mirrors, :last_successful_update_at unless index_exists?(:remote_mirrors, :last_successful_update_at)
  end

  def down
<<<<<<< HEAD
    # ee/db/migrate/20170208144550_add_index_to_mirrors_last_update_at_fields.rb will remove the index.
=======
    remove_index :remote_mirrors, :last_successful_update_at if index_exists? :remote_mirrors, :last_successful_update_at
>>>>>>> 632244e7ad4a77dc5bf7ef407812b875d20569bb
  end
end
