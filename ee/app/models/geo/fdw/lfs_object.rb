# frozen_string_literal: true

module Geo
  module Fdw
    class LfsObject < ::Geo::BaseFdw
      include ObjectStorable

      STORE_COLUMN = :file_store

      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('lfs_objects')

      scope :geo_syncable, -> { with_files_stored_locally }
    end
  end
end
