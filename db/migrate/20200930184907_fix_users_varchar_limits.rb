# frozen_string_literal: true

class FixUsersVarcharLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_table :users do |t| # rubocop:disable Migration/WithLockRetriesDisallowedMethod
        t.change :avatar, :text
        t.change :confirmation_token, :text
        t.change :current_sign_in_ip, :text
        t.change :email, :text, default: ''
        t.change :encrypted_otp_secret, :text
        t.change :encrypted_otp_secret_iv, :text
        t.change :encrypted_otp_secret_salt, :text
        t.change :encrypted_password, :text, default: ''
        t.change :last_sign_in_ip, :text
        t.change :linkedin, :text, default: ''
        t.change :location, :text
        t.change :name, :text
        t.change :notification_email, :text
        t.change :public_email, :text, default: ''
        t.change :reset_password_token, :text
        t.change :skype, :text, default: ''
        t.change :state, :text
        t.change :twitter, :text, default: ''
        t.change :unconfirmed_email, :text
        t.change :username, :text
        t.change :website_url, :text, default: ''
      end
    end
  end

  def down
    # no op
  end
end
