# frozen_string_literal: true

module Resolvers
  class PackagesResolver < BaseResolver
    type Types::PackageType, null: true

    def resolve(**args)
      return unless packages_available?(object, current_user)

      ::Packages::PackagesFinder.new(object).execute
    end

    private

    def packages_available?(object, user)
      ::Gitlab.config.packages.enabled && object.feature_available?(:packages)
    end
  end
end
