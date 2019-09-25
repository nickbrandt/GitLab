# frozen_string_literal: true

class AddIndexToBuildOptions < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_build_on_options'

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_builds, :options,
                         name: INDEX_NAME,
                         using: :gist,
                         opclass: :gist_trgm_ops,
                         where: "options like '%:artifacts:%:reports:%:sast:%'" \
                                " or options like '%:artifacts:%:reports:%:dast:%'" \
                                " or options like '%:artifacts:%:reports:%:dependency_scanning:%'" \
                                " or options like '%:artifacts:%:reports:%:container_scanning:%'"
  end

  def down
    remove_concurrent_index_by_name :ci_builds, INDEX_NAME
  end
end
