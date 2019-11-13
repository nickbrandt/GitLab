# frozen_string_literal: true

module EE
  module Search
    module ProjectService
      extend ::Gitlab::Utils::Override
      include ::Search::Elasticsearchable

      override :execute
      def execute
        return super unless use_elasticsearch?

        ::Gitlab::Elastic::ProjectSearchResults.new(
          current_user,
          params[:search],
          project.id,
          params[:repository_ref]
        )
      end

      def elasticsearchable_scope
        project
      end
    end
  end
end
