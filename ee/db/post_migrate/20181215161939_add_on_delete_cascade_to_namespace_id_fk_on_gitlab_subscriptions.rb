# frozen_string_literal: true

class AddOnDeleteCascadeToNamespaceIdFkOnGitlabSubscriptions < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_foreign_key(:gitlab_subscriptions, column: :namespace_id)

    add_concurrent_foreign_key(:gitlab_subscriptions, :namespaces, column: :namespace_id)
  end

  def down
    # Previously there was a foreign key without a CASCADING DELETE, so we'll
    # just leave the foreign key in place.
  end
end
