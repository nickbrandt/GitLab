# frozen_string_literal: true

module Elastic
  module Latest
    class IssueClassProxy < ApplicationClassProxy
      def elastic_search(query, options: {})
        query_hash =
          if query =~ /#(\d+)\z/
            iid_query_hash(Regexp.last_match(1))
          else
            basic_query_hash(%w(title^2 description), query)
          end

        options[:features] = 'issues'
        query_hash = project_ids_filter(query_hash, options)
        query_hash = confidentiality_filter(query_hash, options[:current_user])

        search(query_hash)
      end

      private

      def confidentiality_filter(query_hash, current_user)
        return query_hash if current_user && current_user.can_read_all_resources?

        filter =
          if current_user
            {
              bool: {
                should: [
                  { term: { confidential: false } },
                  {
                    bool: {
                      must: [
                        { term: { confidential: true } },
                        {
                          bool: {
                            should: [
                              { term: { author_id: current_user.id } },
                              { term: { assignee_id: current_user.id } },
                              { terms: { project_id: current_user.authorized_projects(Gitlab::Access::REPORTER).pluck_primary_key } }
                            ]
                          }
                        }
                      ]
                    }
                  }
                ]
              }
            }
          else
            { term: { confidential: false } }
          end

        query_hash[:query][:bool][:filter] << filter
        query_hash
      end
    end
  end
end
