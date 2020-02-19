# frozen_string_literal: true

module Packages
  module Detail
    class PackagePresenter
      def initialize(package)
        @package = package
      end

      def detail_view
        package_detail = {
          created_at: @package.created_at,
          name: @package.name,
          package_files: @package.package_files.as_json(methods: :download_path),
          package_type: @package.package_type,
          project_id: @package.project_id,
          tags: @package.tags.as_json,
          updated_at: @package.updated_at,
          version: @package.version,
          maven_metadatum: @package.maven_metadatum
        }

        if @package.build_info
          package_detail[:pipeline] = @package.build_info.pipeline.as_json(
            only: [:created_at, :git_commit_message, :id, :sha],
            include: [user: { methods: :avatar_url, only: [:avatar_url, :name] }],
            methods: :git_commit_message
          )
        end

        package_detail.to_json
      end
    end
  end
end
