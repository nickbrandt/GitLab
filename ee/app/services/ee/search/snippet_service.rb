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

      # This method is used in the top-level SearchService, so cannot be in-lined into #execute
      def use_elasticsearch?
        ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: nil)
      end
    end
  end
end
