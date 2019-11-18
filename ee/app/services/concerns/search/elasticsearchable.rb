# frozen_string_literal: true

module Search
  module Elasticsearchable
    def use_elasticsearch?
      return false if params[:basic_search]

      ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: elasticsearchable_scope)
    end

    def elasticsearchable_scope
      raise NotImplementedError
    end
  end
end
