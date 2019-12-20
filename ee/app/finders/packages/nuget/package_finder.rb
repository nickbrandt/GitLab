# frozen_string_literal: true
module Packages
  module Nuget
    class PackageFinder
      MAX_PACKAGES_COUNT = 50

      def initialize(project, package_name:, package_version: nil)
        @project = project
        @package_name = package_name
        @package_version = package_version
      end

      def execute
        packages.limit_recent(MAX_PACKAGES_COUNT)
      end

      private

      def packages
        result = @project.packages
                         .nuget
                         .with_name(@package_name)
        result = result.with_version(@package_version) if @package_version.present?
        result
      end
    end
  end
end
