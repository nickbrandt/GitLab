# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddEnvironmentScopeToCiGroupVariables < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :ci_group_variables, :environment_scope, :string,
                            default: '*', allow_null: false, limit: 255
  end

  def down
    remove_column :ci_group_variables, :environment_scope
  end
end
