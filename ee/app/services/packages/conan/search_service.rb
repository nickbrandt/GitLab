# frozen_string_literal: true

module Packages
  module Conan
    class SearchService < BaseService
      include ActiveRecord::Sanitization::ClassMethods

      WILDCARD = '*'
      RECIPE_SEPARATOR = '@'

      def initialize(user, params)
        super(nil, user, params)
      end

      def execute
        return ServiceResponse.error(message: 'not found', http_status: :not_found) unless feature_available?

        ServiceResponse.success(payload: { results: search_results })
      end

      private

      def search_results
        return [] if wildcard_query?

        search_packages(build_query)
      end

      def wildcard_query?
        params[:query] == WILDCARD
      end

      def build_query
        sanitized_query = sanitize_sql_like(params[:query].delete(WILDCARD))
        return "#{sanitized_query}%" if params[:query].end_with?(WILDCARD)
        return sanitized_query if sanitized_query.include?(RECIPE_SEPARATOR)

        "#{sanitized_query}/%"
      end

      def feature_available?
        Feature.enabled?(:conan_package_registry)
      end

      def search_packages(query)
        Packages::ConanPackageFinder.new(query, current_user).execute.pluck_names
      end
    end
  end
end
