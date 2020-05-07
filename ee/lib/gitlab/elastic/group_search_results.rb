# frozen_string_literal: true

module Gitlab
  module Elastic
    # Always prefer to use the full class namespace when specifying a
    # superclass inside a module, because autoloading can occur in a
    # different order between execution environments.
    class GroupSearchResults < Gitlab::Elastic::SearchResults
      delegate :users, to: :generic_search_results
      delegate :limited_users_count, to: :generic_search_results

      attr_reader :group, :default_project_filter

      def initialize(current_user, limit_project_ids, limit_projects, group, query, public_and_internal_projects, default_project_filter: false)
        super(current_user, query, limit_project_ids, limit_projects, public_and_internal_projects)

        @default_project_filter = default_project_filter
        @group = group
      end

      def generic_search_results
        @generic_search_results ||= Gitlab::GroupSearchResults.new(current_user, limit_projects, group, query, default_project_filter: default_project_filter)
      end
    end
  end
end
