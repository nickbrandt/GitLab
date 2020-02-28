# frozen_string_literal: true

module Gitlab
  module Graphql
    module Loaders
      class BatchEpicIssuesLoader
        # this will assure that no more than 100 queries will be done to fetch issues
        MAX_LOADED_ISSUES = 100_000
        BATCH_SIZE = 1_000

        def initialize(model_id, authorization_filter)
          @model_id = model_id
          @authorization_filter = authorization_filter
        end

        def find
          BatchLoader::GraphQL.for(@model_id).batch(default_value: []) do |ids, loader|
            load_issues(loader, ids)
          end
        end

        private

        def load_issues(loader, ids)
          issues = ::EpicIssue.related_issues_for_batches(ids)
          issues.each_batch(of: BATCH_SIZE, column: 'relative_position') do |batch, idx|
            process_batch(loader, batch, idx)
          end
        end

        def process_batch(loader, batch, idx)
          Epic.related_issues(preload: { project: [:namespace, :project_feature] })
            .merge(batch.except(:select)).each do |issue|
            ensure_limit_not_exceeded!(idx)

            loader.call(issue.epic_id) do |memo|
              unless memo.is_a?(Gitlab::Graphql::FilterableArray)
                # memo is an empty array by default
                memo = Gitlab::Graphql::FilterableArray.new(@authorization_filter)
              end

              memo << issue
            end
          end
        end

        def ensure_limit_not_exceeded!(current_index)
          if current_index * BATCH_SIZE > MAX_LOADED_ISSUES
            raise Gitlab::Graphql::Errors::ArgumentError, 'Too many epic issues requested.'
          end
        end
      end
    end
  end
end
