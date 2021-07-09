# frozen_string_literal: true

module Elastic
  module Latest
    class IssueClassProxy < ApplicationClassProxy
      include StateFilter

      def elastic_search(query, options: {})
        query_hash =
          if query =~ /#(\d+)\z/
            iid_query_hash(Regexp.last_match(1))
          else
            # iid field can be added here as lenient option will
            # pardon format errors, like integer out of range.
            fields = %w[iid^3 title^2 description]
            basic_query_hash(fields, query, count_only: options[:count_only])
          end

        options[:features] = 'issues'
        options[:no_join_project] = true
        context.name(:issue) do
          query_hash = context.name(:authorized) { project_ids_filter(query_hash, options) }
          query_hash = context.name(:confidentiality) { confidentiality_filter(query_hash, options) }
          query_hash = context.name(:match) { state_filter(query_hash, options) }
        end
        query_hash = apply_sort(query_hash, options)

        search(query_hash, options)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def preload_indexing_data(relation)
        relation.includes(:issue_assignees, :award_emoji, project: [:project_feature])
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      # Builds an elasticsearch query that will select documents from a
      # set of projects for Group and Project searches, taking user access
      # rules for issues into account. Relies upon super for Global searches
      def project_ids_filter(query_hash, options)
        return super if options[:public_and_internal_projects]

        current_user = options[:current_user]
        scoped_project_ids = scoped_project_ids(current_user, options[:project_ids])
        return super if scoped_project_ids == :any

        context.name(:project) do
          query_hash[:query][:bool][:filter] ||= []
          query_hash[:query][:bool][:filter] << {
            terms: {
              _name: context.name,
              project_id: filter_ids_by_feature(scoped_project_ids, current_user, 'issues')
            }
          }
        end

        query_hash
      end

      def confidentiality_filter(query_hash, options)
        current_user = options[:current_user]
        project_ids = options[:project_ids]

        if [true, false].include?(options[:confidential])
          query_hash[:query][:bool][:filter] << { term: { confidential: options[:confidential] } }
        end

        return query_hash if current_user&.can_read_all_resources?

        scoped_project_ids = scoped_project_ids(current_user, project_ids)
        authorized_project_ids = authorized_project_ids(current_user, options)

        # we can shortcut the filter if the user is authorized to see
        # all the projects for which this query is scoped on
        unless scoped_project_ids == :any || scoped_project_ids.empty?
          return query_hash if authorized_project_ids.to_set == scoped_project_ids.to_set
        end

        filter = { term: { confidential: { _name: context.name(:non_confidential), value: false } } }

        if current_user
          filter = {
              bool: {
                should: [
                  { term: { confidential: { _name: context.name(:non_confidential), value: false } } },
                  {
                    bool: {
                      must: [
                        { term: { confidential: true } },
                        {
                          bool: {
                            should: [
                              { term: { author_id: { _name: context.name(:as_author), value: current_user.id } } },
                              { term: { assignee_id: { _name: context.name(:as_assignee), value: current_user.id } } },
                              { terms: { _name: context.name(:project, :membership, :id), project_id: authorized_project_ids } }
                            ]
                          }
                        }
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
