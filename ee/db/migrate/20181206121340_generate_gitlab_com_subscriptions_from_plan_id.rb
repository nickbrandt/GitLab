# frozen_string_literal: true

class GenerateGitlabComSubscriptionsFromPlanId < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'GenerateGitlabSubscriptions'.freeze

  class Namespace < ActiveRecord::Base
    self.table_name = 'namespaces'

    scope :with_plan, -> { where.not(plan_id: nil) }
    scope :without_subscription, -> do
      joins("LEFT JOIN gitlab_subscriptions ON namespaces.id = gitlab_subscriptions.namespace_id")
      .where(gitlab_subscriptions: { id: nil })
    end

    include ::EachBatch
  end

  disable_ddl_transaction!

  def up
    return unless Gitlab.dev_env_or_com?

    say 'Populating GitlabSubscription from Namespace with a `plan_id`'

    bulk_queue_background_migration_jobs_by_range(Namespace.with_plan.without_subscription, MIGRATION)
  end

  def down
    GitlabSubscription.delete_all
  end
end
