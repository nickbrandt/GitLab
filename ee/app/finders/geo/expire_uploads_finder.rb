# frozen_string_literal: true

module Geo
  class ExpireUploadsFinder
    def find_project_uploads(project)
      if Gitlab::Geo::Fdw.enabled?
        Geo::Fdw::Upload.for_model_with_type(project, 'file')
      else
        legacy_find_project_uploads(project)
      end
    end

    def find_file_registries_uploads(project)
      if Gitlab::Geo::Fdw.enabled?
        Gitlab::Geo::Fdw::FileRegistryQueryBuilder.new
          .for_model(project)
          .with_type('file')
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
      upload_type = 'file'

      Geo::FileRegistry.joins(<<~SQL)
        JOIN (VALUES #{values_sql})
          AS uploads (id)
          ON uploads.id = file_registry.file_id
         AND file_registry.file_type='#{upload_type}'
      SQL
    end
    # rubocop:enable CodeReuse/ActiveRecord

    # rubocop:disable CodeReuse/ActiveRecord
    def legacy_find_project_uploads(project)
      file_registry_ids = legacy_find_file_registries_uploads(project).pluck(:file_id)
      return Upload.none if file_registry_ids.empty?

      values_sql = file_registry_ids.map { |f_id| "(#{f_id})" }.join(',')

      Upload.joins(<<~SQL)
        JOIN (VALUES #{values_sql})
          AS file_registry (file_id)
          ON (file_registry.file_id = uploads.id)
      SQL
    end
    # rubocop:enable CodeReuse/ActiveRecord
  end
end
