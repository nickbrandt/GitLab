# frozen_string_literal: true

class AddHostedPlanIdFkToGitlabSubscriptions < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :gitlab_subscriptions, :plans, column: :hosted_plan_id
  end

  def down
    remove_foreign_key :gitlab_subscriptions, column: :hosted_plan_id
  end
end
