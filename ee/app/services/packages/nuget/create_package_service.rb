# frozen_string_literal: true

module Packages
  module Nuget
    class CreatePackageService < BaseService
      PACKAGE_NAME = 'NuGet.Package'
      PACKAGE_VERSION = '0.0.0'

      def execute
        project.packages.nuget.create!(
          name: PACKAGE_NAME,
          version: PACKAGE_VERSION
        )
      end
    end
  end
end
