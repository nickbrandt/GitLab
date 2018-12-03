# frozen_string_literal: true

module Elastic
  module ProjectsSearch
    extend ActiveSupport::Concern

    TRACKED_FEATURE_SETTINGS = %w(
      issues_access_level
      merge_requests_access_level
      snippets_access_level
      wiki_access_level
      repository_access_level
    ).freeze

    included do
      include ApplicationSearch

      def as_indexed_json(options = {})
        # We don't use as_json(only: ...) because it calls all virtual and serialized attributtes
        # https://gitlab.com/gitlab-org/gitlab-ee/issues/349
        data = {}

        [
          :id,
          :name,
          :path,
          :description,
          :namespace_id,
          :created_at,
          :updated_at,
          :archived,
          :visibility_level,
          :last_activity_at,
          :name_with_namespace,
          :path_with_namespace
        ].each do |attr|
          data[attr.to_s] = safely_read_attribute_for_elasticsearch(attr)
        end

        # Set it as a parent in our `project => child` JOIN field
        data['join_field'] = es_type

        # ES6 is now single-type per index, so we implement our own typing
        data['type'] = 'project'

        TRACKED_FEATURE_SETTINGS.each do |feature|
          data[feature] = project_feature.public_send(feature) # rubocop:disable GitlabSecurity/PublicSend
        end

        data
      end

      def self.elastic_search(query, options: {})
        options[:in] = %w(name^10 name_with_namespace^2 path_with_namespace path^9 description)

        query_hash = basic_query_hash(options[:in], query)

        filters = []

        if options[:namespace_id]
          filters << {
            terms: {
              namespace_id: [options[:namespace_id]].flatten
            }
          }
        end

        if options[:non_archived]
          filters << {
            terms: {
              archived: [!options[:non_archived]].flatten
            }
          }
        end

        if options[:visibility_levels]
          filters << {
            terms: {
              visibility_level: [options[:visibility_levels]].flatten
            }
          }
        end

        if options[:project_ids]
          filters << {
            bool: project_ids_query(options[:current_user], options[:project_ids], options[:public_and_internal_projects])
          }
        end

        query_hash[:query][:bool][:filter] = filters

        query_hash[:sort] = [:_score]

        self.__elasticsearch__.search(query_hash)
      end
    end
  end
end
