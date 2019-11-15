# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class BatchEpicIssuesLoader
        # this will assure that no more than 100 queries will be done to fetch issues
        MAX_LOADED_ISSUES = 100_000

        def initialize(model_id, authorization_filter)
          @model_id = model_id
          @authorization_filter = authorization_filter
        end

        def find
          BatchLoader::GraphQL.for(@model_id).batch(default_value: []) do |ids, loader|
            issues = ::Epic.related_issues(ids: ids, preload: { project: [:namespace, :project_feature] })
            load_issues(loader, issues)
          end
        end

        private

        # rubocop: disable CodeReuse/ActiveRecord
        def load_issues(loader, issues)
          issues.find_each(batch_size: 1000).with_index do |issue, idx|
            if idx > MAX_LOADED_ISSUES
              raise Gitlab::Graphql::Errors::ArgumentError, 'Too many epic issues requested.'
            end

            loader.call(issue.epic_id) do |memo|
              unless memo.is_a?(Gitlab::Graphql::FilterableArray)
                # memo is an empty array by default
                memo = Gitlab::Graphql::FilterableArray.new(@authorization_filter)
              end

              memo << issue
            end
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
