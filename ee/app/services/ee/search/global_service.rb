# frozen_string_literal: true

module EE
  module Search
    module GlobalService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize
      include ::Search::Elasticsearchable

      override :execute
      def execute
        return super unless use_elasticsearch?

        ::Gitlab::Elastic::SearchResults.new(
          current_user,
          params[:search],
          projects,
          public_and_internal_projects: elastic_global,
          filters: { state: params[:state] }
        )
      end

      def elasticsearchable_scope
        nil
      end

      def elastic_global
        true
      end

      override :allowed_scopes
      def allowed_scopes
        return super unless use_elasticsearch?

        strong_memoize(:ee_allowed_scopes) do
          super.tap do |ce_scopes|
            ce_scopes.concat(%w[notes wiki_blobs blobs commits])
          end
        end
      end
    end
  end
end
