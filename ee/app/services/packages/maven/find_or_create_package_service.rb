# frozen_string_literal: true
module Packages
  module Maven
    class FindOrCreatePackageService < BaseService
      MAVEN_METADATA_FILE = 'maven-metadata.xml'.freeze

      def execute
        package = ::Packages::Maven::PackageFinder
          .new(params[:path], current_user, project: project).execute

        unless package
          package_name, _, version = params[:path].rpartition('/')
          package_params = {
            name: package_name,
            path: params[:path],
            version: version,
            build: params[:build]
          }

          package = ::Packages::Maven::CreatePackageService
            .new(project, current_user, package_params).execute
        end

        package
      end
    end
  end
end
