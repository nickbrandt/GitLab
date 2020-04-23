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
          package_files: @package.package_files.map { |pf| build_package_file_view(pf) },
          package_type: @package.package_type,
          project_id: @package.project_id,
          tags: @package.tags.as_json,
          updated_at: @package.updated_at,
          version: @package.version
        }

        package_detail[:maven_metadatum] = @package.maven_metadatum if @package.maven_metadatum
        package_detail[:pipeline] = build_pipeline_info(@package.build_info.pipeline) if @package.build_info

        package_detail
      end

      def build_package_file_view(package_file)
        {
          created_at: package_file.created_at,
          download_path: package_file.download_path,
          file_name: package_file.file_name,
          size: package_file.size
        }
      end

      def build_pipeline_info(pipeline_info)
        {
          created_at: pipeline_info.created_at,
          id: pipeline_info.id,
          sha: pipeline_info.sha,
          ref: pipeline_info.ref,
          git_commit_message: pipeline_info.git_commit_message,
          user: build_user_info(pipeline_info.user),
          project: {
            name: pipeline_info.project.name,
            web_url: pipeline_info.project.web_url
          }
        }
      end

      def build_user_info(user)
        return unless user

        {
          avatar_url: user.avatar_url,
          name: user.name
        }
      end
    end
  end
end
