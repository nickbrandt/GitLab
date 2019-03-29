# frozen_string_literal: true

module EE
  module SearchService
    # This is a proper method instead of a `delegate` in order to
    # avoid adding unnecessary methods to Search::SnippetService
    def use_elasticsearch?
      search_service.use_elasticsearch?
    end
  end
end
