# frozen_string_literal: true

module Packages
  class ConanPackageSearchService
    include ActiveRecord::Sanitization::ClassMethods

    def initialize(query, user)
      @query = query
      @user = user
    end

    def execute
      sanitized_query = sanitize_sql_like(@query.delete('*'))
      search_query = "#{sanitized_query}/%"
      search_query = "#{sanitized_query}%" if @query.include?("*")

      results = packages.where("name like ?", search_query).map(&:name)

      { "results": results }
    end

    private

    def packages
      Packages::Package.conan
    end
  end
end
