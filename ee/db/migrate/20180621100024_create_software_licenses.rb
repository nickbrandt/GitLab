# frozen_string_literal: true

# A software license. Used in the License Management feature for CI/CD.
class CreateSoftwareLicenses < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    create_table :software_licenses do |t|
      t.string :name, null: false, unique: true, index: true
    end
  end
end
