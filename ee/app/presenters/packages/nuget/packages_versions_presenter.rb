# frozen_string_literal: true

module Packages
  module Nuget
    class PackagesVersionsPresenter
      attr_reader :packages

      def initialize(packages)
        @packages = packages
      end

      def versions
        @packages.pluck_versions.sort
      end
    end
  end
end
