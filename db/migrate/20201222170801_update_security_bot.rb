# frozen_string_literal: true

class UpdateSecurityBot < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    SECURITY_BOT_TYPE = 8
  end

  def up
    bot = User.where(user_type: User::SECURITY_BOT_TYPE).last

    return unless bot
    return if bot.confirmed_at

    bot.update_attribute(:confirmed_at, Time.zone.now)
  end

  # no-op
  def down
  end
end
