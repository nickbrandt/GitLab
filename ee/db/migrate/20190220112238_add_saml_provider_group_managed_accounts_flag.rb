# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddSamlProviderGroupManagedAccountsFlag < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :saml_providers, :enforced_group_managed_accounts, :boolean, default: false, allow_null: false
  end

  def down
    remove_column :saml_providers, :enforced_group_managed_accounts
  end
end
