# frozen_string_literal: true

module EE
  module SearchService
    EE_REDACTABLE_RESULTS = [
      Kaminari::PaginatableArray,
      Elasticsearch::Model::Response::Records
    ].freeze

    # This is a proper method instead of a `delegate` in order to
    # avoid adding unnecessary methods to Search::SnippetService
    def use_elasticsearch?
      search_service.use_elasticsearch?
    end

    def redactable_results
      super + EE_REDACTABLE_RESULTS
    end

    def valid_query_length?
      return true if use_elasticsearch?

      super
    end

    def valid_terms_count?
      return true if use_elasticsearch?

      super
    end
  end
end
