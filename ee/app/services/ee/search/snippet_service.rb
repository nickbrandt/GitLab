# frozen_string_literal: true

module EE
  module Search
    module SnippetService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        return super unless use_elasticsearch?

        ::Gitlab::Elastic::SnippetSearchResults.new(current_user, params[:search], elastic_projects, nil, true)
      end

      override :elasticsearchable_scope
      def elasticsearchable_scope
        nil
      end
    end
  end
end
