# frozen_string_literal: true

class UpdateSecurityBot < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    SECURITY_BOT_TYPE = 8
  end

  def up
    bot = User.find_by(user_type: User::SECURITY_BOT_TYPE, confirmed_at: nil)

    return unless bot

    bot.update_attribute(:confirmed_at, Time.current)
  end

  # no-op
  def down
  end
end
