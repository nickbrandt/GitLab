# frozen_string_literal: true

module EE
  module SearchService
    # Both of these classes conform to the necessary pagination interface and
    # both of these are returned in various places from search results. There
    # doesn't seem to be a common ancestor to check.
    REDACTABLE_RESULTS = [Kaminari::PaginatableArray, Elasticsearch::Model::Response::Records].freeze

    # This is a proper method instead of a `delegate` in order to
    # avoid adding unnecessary methods to Search::SnippetService
    def use_elasticsearch?
      search_service.use_elasticsearch?
    end

    def search_objects
      results = super
      redact_unauthorized_results(results)
    end

    def redact_unauthorized_results(results)
      return results unless REDACTABLE_RESULTS.any? { |redactable| results.is_a?(redactable) }

      filtered_results = []
      permitted_results = results.select do |o|
        next true unless o.respond_to?(:to_ability_name)

        ability = :"read_#{o.to_ability_name}"
        if Ability.allowed?(current_user, ability, o)
          true
        else
          # Redact any search result the user may not have access to. This
          # could be due to incorrect data in the index or a bug in our query
          # so we log this as an error.
          filtered_results << { ability: ability, id: o.id, class_name: o.class.name }
          false
        end
      end

      if filtered_results.any?
        logger.error(message: "redacted_search_results", filtered: filtered_results, current_user_id: current_user&.id, query: params[:search])
      end

      Kaminari.paginate_array(
        permitted_results,
        total_count: results.total_count,
        limit: results.limit_value,
        offset: results.offset_value
      )
    end

    private

    def logger
      @logger ||= ::Gitlab::Elasticsearch::Logger.build
    end
  end
end
