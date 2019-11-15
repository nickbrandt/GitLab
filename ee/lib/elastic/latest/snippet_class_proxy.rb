# frozen_string_literal: true

module Elastic
  module Latest
    class SnippetClassProxy < ApplicationClassProxy
      def elastic_search(query, options: {})
        query_hash = basic_query_hash(%w(title file_name), query)
        query_hash = filter(query_hash, options[:user])

        search(query_hash)
      end

      def elastic_search_code(query, options: {})
        query_hash = basic_query_hash(%w(content), query)
        query_hash = filter(query_hash, options[:user])

        search(query_hash)
      end

      def es_type
        target.base_class.name.underscore
      end

      private

      def filter(query_hash, user)
        return query_hash if user && user.full_private_access?

        filter =
          if user
            {
              bool: {
                should: [
                  { term: { author_id: user.id } },
                  { terms: { project_id: authorized_project_ids_for_user(user) } },
                  {
                    bool: {
                      filter: [
                        { terms: { visibility_level: [Snippet::PUBLIC, Snippet::INTERNAL] } },
                        { term: { type: self.es_type } }
                      ],
                      must_not: { exists: { field: 'project_id' } }
                    }
                  }
                ]
              }
            }
          else
            {
              bool: {
                filter: [
                  { term: { visibility_level: Snippet::PUBLIC } },
                  { term: { type: self.es_type } }
                ],
                must_not: { exists: { field: 'project_id' } }
              }
            }
          end

        query_hash[:query][:bool][:filter] = filter
        query_hash
      end

      def authorized_project_ids_for_user(user)
        if Ability.allowed?(user, :read_cross_project)
          user
            .authorized_projects(Gitlab::Access::GUEST)
            .filter_by_feature_visibility(:snippets, user)
            .pluck_primary_key
        else
          []
        end
      end
    end
  end
end
