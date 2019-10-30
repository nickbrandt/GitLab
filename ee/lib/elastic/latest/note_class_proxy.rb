# frozen_string_literal: true

module Elastic
  module Latest
    class NoteClassProxy < ApplicationClassProxy
      def es_type
        'note'
      end

      def elastic_search(query, options: {})
        options[:in] = ['note']

        query_hash = basic_query_hash(%w[note], query)
        query_hash = project_ids_filter(query_hash, options)
        query_hash = confidentiality_filter(query_hash, options[:current_user])

        query_hash[:sort] = [
          { updated_at: { order: :desc } },
          :_score
        ]

        query_hash[:highlight] = highlight_options(options[:in])

        search(query_hash)
      end

      private

      def confidentiality_filter(query_hash, current_user)
        return query_hash if current_user&.full_private_access?

        filter = {
          bool: {
            should: [
              { bool: { must_not: [{ exists: { field: :issue } }] } },
              { term: { "issue.confidential" => false } }
            ]
          }
        }

        if current_user
          filter[:bool][:should] << {
            bool: {
              must: [
                { term: { "issue.confidential" => true } },
                {
                  bool: {
                    should: [
                      { term: { "issue.author_id" => current_user.id } },
                      { term: { "issue.assignee_id" => current_user.id } },
                      { terms: { "project_id" => current_user.authorized_projects(Gitlab::Access::REPORTER).pluck_primary_key } }
                    ]
                  }
                }
              ]
            }
          }
        end

        query_hash[:query][:bool][:filter] << filter
        query_hash
      end
    end
  end
end
