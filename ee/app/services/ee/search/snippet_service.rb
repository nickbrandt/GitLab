# frozen_string_literal: true

module EE
  module Search
    module SnippetService
      extend ::Gitlab::Utils::Override

      override :execute

      def execute
        if ::Gitlab::CurrentSettings.elasticsearch_search?
          ::Gitlab::Elastic::SnippetSearchResults.new(current_user, params[:search])
        else
          super
        end
      end
    end
  end
end
