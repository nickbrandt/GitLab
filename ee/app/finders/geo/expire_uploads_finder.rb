# frozen_string_literal: true

module Geo
  class ExpireUploadsFinder
    UPLOAD_TYPE = 'file'

    def find_project_uploads(project)
      Geo::Fdw::Upload.for_model_with_type(project, UPLOAD_TYPE)
    end

    def find_file_registries_uploads(project)
      if Gitlab::Geo::Fdw.enabled?
        Gitlab::Geo::Fdw::UploadRegistryQueryBuilder.new
          .for_model(project)
          .with_type(UPLOAD_TYPE)
      else
        legacy_find_file_registries_uploads(project)
      end
    end

    private

    # rubocop:disable CodeReuse/ActiveRecord
    def legacy_find_file_registries_uploads(project)
      upload_ids = Upload.for_model(project).pluck_primary_key
      return Geo::FileRegistry.none if upload_ids.empty?

      values_sql = upload_ids.map { |id| "(#{id})" }.join(',')

      Geo::FileRegistry.joins(<<~SQL)
        JOIN (VALUES #{values_sql})
          AS uploads (id)
          ON uploads.id = file_registry.file_id
         AND file_registry.file_type='#{UPLOAD_TYPE}'
      SQL
    end
    # rubocop:enable CodeReuse/ActiveRecord
  end
end
