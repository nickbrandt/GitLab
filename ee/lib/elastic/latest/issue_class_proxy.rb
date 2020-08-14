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
        query_hash = confidentiality_filter(query_hash, options[:current_user], options[:project_ids])

        search(query_hash, options)
      end

      private

      def user_has_access_to_confidential_issues?(authorized_project_ids, project_ids)
        # is_a?(Array) is needed because we might receive project_ids: :any
        return false unless authorized_project_ids && project_ids.is_a?(Array)

        (project_ids - authorized_project_ids).empty?
      end

      def confidentiality_filter(query_hash, current_user, project_ids)
        return query_hash if current_user&.can_read_all_resources?

        authorized_project_ids = current_user&.authorized_projects(Gitlab::Access::REPORTER)&.pluck_primary_key
        return query_hash if user_has_access_to_confidential_issues?(authorized_project_ids, project_ids)

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
                              { terms: { project_id: authorized_project_ids } }
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
