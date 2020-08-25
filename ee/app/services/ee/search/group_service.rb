# frozen_string_literal: true

module EE
  module Search
    module GroupService
      extend ::Gitlab::Utils::Override

      override :elasticsearchable_scope
      def elasticsearchable_scope
        group
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
          params[:search],
          projects,
          group: group,
          public_and_internal_projects: elastic_global
        )
      end
    end
  end
end
