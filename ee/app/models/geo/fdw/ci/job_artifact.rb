# frozen_string_literal: true

module Geo
  module Fdw
    module Ci
      class JobArtifact < ::Geo::BaseFdw
        include ObjectStorable

        STORE_COLUMN = :file_store

        self.table_name = Gitlab::Geo::Fdw.foreign_table_name('ci_job_artifacts')

        belongs_to :project, class_name: 'Geo::Fdw::Project', inverse_of: :job_artifacts

        scope :not_expired, -> { where('expire_at IS NULL OR expire_at > ?', Time.current) }
        scope :geo_syncable, -> { with_files_stored_locally.not_expired }
        scope :project_id_in, ->(ids) { joins(:project).merge(Geo::Fdw::Project.id_in(ids)) }
      end
    end
  end
end
