# frozen_string_literal: true

module EE
  module SearchController
    extend ActiveSupport::Concern

    prepended do
      before_action :track_advanced_search, only: :show, if: -> { request.format.html? && request.headers['DNT'] != '1' }
    end

    private

    def track_advanced_search
      # track unique users of advanced global search
      track_unique_redis_hll_event("i_search_advanced", :search_track_unique_users) if search_service.use_elasticsearch?

      # track unique users who search against paid groups/projects
      track_unique_redis_hll_event("i_search_paid", :search_track_unique_users) if (search_service.project || search_service.group)&.feature_available?(:elastic_search)
    end
  end
end
