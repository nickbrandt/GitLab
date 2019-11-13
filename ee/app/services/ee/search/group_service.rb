# frozen_string_literal: true

module EE
  module Search
    module GroupService
      extend ::Gitlab::Utils::Override

      override :elasticsearchable_scope
      def elasticsearchable_scope
        group
      end

      override :elastic_projects
      def elastic_projects
        @elastic_projects ||= projects.pluck(:id) # rubocop:disable CodeReuse/ActiveRecord
      end

      override :elastic_global
      def elastic_global
        false
      end

      override :execute
      def execute
        return super unless use_elasticsearch?

        ::Gitlab::Elastic::GroupSearchResults.new(
          current_user,
          elastic_projects,
          projects,
          group,
          params[:search],
          elastic_global,
          default_project_filter: default_project_filter
        )
      end
    end
  end
end
