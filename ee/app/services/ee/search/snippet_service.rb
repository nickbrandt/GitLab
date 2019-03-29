# frozen_string_literal: true

module EE
  module Search
    module SnippetService
      extend ::Gitlab::Utils::Override

      override :execute

      def execute
        if use_elasticsearch?
          ::Gitlab::Elastic::SnippetSearchResults.new(current_user, params[:search])
        else
          super
        end
      end

      # This method is used in the top-level SearchService, so cannot be in-lined into #execute
      def use_elasticsearch?
        ::Gitlab::CurrentSettings.elasticsearch_search?
      end
    end
  end
end
