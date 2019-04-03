# frozen_string_literal: true

class IndexUsersBotType < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    enum bot_type: { support_bot: 1 }
  end

  def up
    remove_concurrent_index :users, :bot_type
    add_concurrent_index :users, :bot_type

    remove_concurrent_index :users, :state, name: internal_index
    add_concurrent_index :users, :state,
      name: internal_index,
      where: 'ghost <> true AND bot_type IS NULL'

    User
      .where(support_bot: true)
      .update_all(bot_type: User.bot_types[:support_bot])
  end

  def down
    User
      .where(bot_type: User.bot_types[:support_bot])
      .update_all(support_bot: true)

    remove_concurrent_index :users, :state, name: internal_index
    remove_concurrent_index :users, :bot_type
  end

  private

  def internal_index
    'index_users_on_state_and_internal'
  end
end
