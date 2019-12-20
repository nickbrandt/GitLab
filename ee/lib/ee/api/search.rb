# frozen_string_literal: true

module EE
  module API
    module Search
      extend ActiveSupport::Concern

      prepended do
        helpers do
          extend ::Gitlab::Utils::Override

          ELASTICSEARCH_SCOPES = %w(wiki_blobs blobs commits).freeze

          override :verify_search_scope!
          def verify_search_scope!
            if ELASTICSEARCH_SCOPES.include?(params[:scope]) && !elasticsearch?
              render_api_error!({ error: 'Scope not supported without Elasticsearch!' }, 400)
            end
          end

          def elasticsearch?
            ::Gitlab::CurrentSettings.elasticsearch_search?
          end

          override :process_results
          def process_results(results)
            return [] if results.empty?

            if results.any? { |result| result.is_a?(::Elasticsearch::Model::Response::Result) && result.respond_to?(:blob) }
              return paginate(results).map { |blob| ::Gitlab::Elastic::SearchResults.parse_search_result(blob) }
            end

            super
          end
        end
      end
    end
  end
end
