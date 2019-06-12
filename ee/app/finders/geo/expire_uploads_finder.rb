# frozen_string_literal: true

module Geo
  class ExpireUploadsFinder
    UPLOAD_TYPE = 'file'

    def find_project_uploads(project)
      Geo::Fdw::Upload.for_model_with_type(project, UPLOAD_TYPE)
    end

    def find_file_registries_uploads(project)
      Gitlab::Geo::Fdw::UploadRegistryQueryBuilder.new
        .for_model(project)
        .with_type(UPLOAD_TYPE)
    end
  end
end
