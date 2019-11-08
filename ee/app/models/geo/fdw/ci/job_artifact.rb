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
        scope :project_id_in, ->(ids) { where(project_id: ids) }

        class << self
          def inner_join_job_artifact_registry
            join_statement =
              arel_table
                .join(job_artifact_registry_table, Arel::Nodes::InnerJoin)
                .on(arel_table[:id].eq(job_artifact_registry_table[:artifact_id]))

            joins(join_statement.join_sources)
          end

          def missing_job_artifact_registry
            left_outer_join_job_artifact_registry
              .where(job_artifact_registry_table[:id].eq(nil))
          end

          private

          def job_artifact_registry_table
            Geo::JobArtifactRegistry.arel_table
          end

          def left_outer_join_job_artifact_registry
            join_statement =
              arel_table
                .join(job_artifact_registry_table, Arel::Nodes::OuterJoin)
                .on(arel_table[:id].eq(job_artifact_registry_table[:artifact_id]))

            joins(join_statement.join_sources)
          end
        end
      end
    end
  end
end
