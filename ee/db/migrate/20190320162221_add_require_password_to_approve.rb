# frozen_string_literal: true

class AddRequirePasswordToApprove < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :projects, :require_password_to_approve, :boolean
  end
end
