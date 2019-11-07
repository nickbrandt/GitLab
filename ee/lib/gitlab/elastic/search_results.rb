# frozen_string_literal: true

module Gitlab
  module Elastic
    class SearchResults
      include Gitlab::Utils::StrongMemoize

      attr_reader :current_user, :query, :public_and_internal_projects

      # Limit search results by passed project ids
      # It allows us to search only for projects user has access to
      attr_reader :limit_project_ids, :limit_projects

      delegate :users, to: :generic_search_results
      delegate :limited_users_count, to: :generic_search_results

      def initialize(current_user, query, limit_project_ids, limit_projects = nil, public_and_internal_projects = true)
        @current_user = current_user
        @limit_project_ids = limit_project_ids
        @limit_projects = limit_projects
        @query = query
        @public_and_internal_projects = public_and_internal_projects
      end

      def objects(scope, page = 1)
        page = (page || 1).to_i

        case scope
        when 'projects'
          eager_load(projects, page, eager: [:route, :namespace])
        when 'issues'
          eager_load(issues, page, eager: { project: [:route, :namespace] })
        when 'merge_requests'
          eager_load(merge_requests, page, eager: { target_project: [:route, :namespace] })
        when 'milestones'
          eager_load(milestones, page, eager: { project: [:route, :namespace] })
        when 'notes'
          eager_load(notes, page, eager: { project: [:route, :namespace] })
        when 'blobs'
          blobs.page(page).per(per_page)
        when 'wiki_blobs'
          wiki_blobs.page(page).per(per_page)
        when 'commits'
          commits(page: page, per_page: per_page)
        when 'users'
          users.page(page).per(per_page)
        else
          Kaminari.paginate_array([])
        end
      end

      def generic_search_results
        @generic_search_results ||= Gitlab::SearchResults.new(current_user, limit_projects, query)
      end

      def formatted_count(scope)
        case scope
        when 'projects'
          projects_count.to_s
        when 'notes'
          notes_count.to_s
        when 'blobs'
          blobs_count.to_s
        when 'wiki_blobs'
          wiki_blobs_count.to_s
        when 'commits'
          commits_count.to_s
        when 'issues'
          issues_count.to_s
        when 'merge_requests'
          merge_requests_count.to_s
        when 'milestones'
          milestones_count.to_s
        when 'users'
          generic_search_results.formatted_count('users')
        end
      end

      def projects_count
        @projects_count ||= projects.total_count
      end

      def notes_count
        @notes_count ||= notes.total_count
      end

      def blobs_count
        @blobs_count ||= blobs.total_count
      end

      def wiki_blobs_count
        @wiki_blobs_count ||= wiki_blobs.total_count
      end

      def commits_count
        @commits_count ||= commits.total_count
      end

      def issues_count
        @issues_count ||= issues.total_count
      end

      def merge_requests_count
        @merge_requests_count ||= merge_requests.total_count
      end

      def milestones_count
        @milestones_count ||= milestones.total_count
      end

      def single_commit_result?
        false
      end

      def self.parse_search_result(result)
        ref = result["_source"]["blob"]["commit_sha"]
        filename = result["_source"]["blob"]["path"]
        extname = File.extname(filename)
        basename = filename.sub(/#{extname}$/, '')
        content = result["_source"]["blob"]["content"]
        project_id = result['_source']['project_id'].to_i
        total_lines = content.lines.size

        term =
          if result['highlight']
            highlighted = result['highlight']['blob.content']
            highlighted && highlighted[0].match(/gitlabelasticsearch→(.*?)←gitlabelasticsearch/)[1]
          end

        found_line_number = 0

        content.each_line.each_with_index do |line, index|
          if term && line.include?(term)
            found_line_number = index
            break
          end
        end

        from = if found_line_number >= 2
                 found_line_number - 2
               else
                 found_line_number
               end

        to = if (total_lines - found_line_number) > 3
               found_line_number + 2
             else
               found_line_number
             end

        data = content.lines[from..to]

        ::Gitlab::Search::FoundBlob.new(
          filename: filename,
          basename: basename,
          ref: ref,
          startline: from + 1,
          data: data.join,
          project_id: project_id
        )
      end

      private

      # Apply some eager loading to the `records` of an ES result object without
      # losing pagination information
      def eager_load(es_result, page, eager:)
        paginated_base = es_result.page(page).per(per_page)
        relation = paginated_base.records.includes(eager) # rubocop:disable CodeReuse/ActiveRecord

        Kaminari.paginate_array(
          relation,
          total_count: paginated_base.total_count,
          limit: per_page,
          offset: per_page * (page - 1)
        )
      end

      def base_options
        {
          current_user: current_user,
          project_ids: limit_project_ids,
          public_and_internal_projects: public_and_internal_projects
        }
      end

      def projects
        strong_memoize(:projects) do
          Project.elastic_search(query, options: base_options)
        end
      end

      def issues
        strong_memoize(:issues) do
          Issue.elastic_search(query, options: base_options)
        end
      end

      def milestones
        strong_memoize(:milestones) do
          # Must pass 'issues' and 'merge_requests' to check
          # if any of the features is available for projects in ApplicationClassProxy#project_ids_query
          # Otherwise it will ignore project_ids and return milestones
          # from projects with milestones disabled.
          options = base_options
          options[:features] = [:issues, :merge_requests]

          Milestone.elastic_search(query, options: options)
        end
      end

      def merge_requests
        strong_memoize(:merge_requests) do
          options = base_options.merge(project_ids: non_guest_project_ids)
          MergeRequest.elastic_search(query, options: options)
        end
      end

      def notes
        strong_memoize(:notes) do
          Note.elastic_search(query, options: base_options)
        end
      end

      def blobs
        return Kaminari.paginate_array([]) if query.blank?

        strong_memoize(:blobs) do
          opt = {
            additional_filter: repository_filter
          }

          Repository.search(
            query,
            type: :blob,
            options: opt.merge({ highlight: true })
          )[:blobs][:results].response
        end
      end

      def wiki_blobs
        return Kaminari.paginate_array([]) if query.blank?

        strong_memoize(:wiki_blobs) do
          opt = {
            additional_filter: wiki_filter
          }

          ProjectWiki.search(
            query,
            type: :wiki_blob,
            options: opt.merge({ highlight: true })
          )[:wiki_blobs][:results].response
        end
      end

      # We're only memoizing once because this object only ever gets used to show a single page of results
      # during its lifetime. We _must_ memoize the page we want because `#commits_count` does not have any
      # inkling of the current page we're on - if we were to memoize with dynamic parameters we would end up
      # hitting ES twice for any page that's not page 1, and that's something we want to avoid.
      #
      # It is safe to memoize the page we get here because this method is _always_ called before `#commits_count`
      def commits(page: 1, per_page: 20)
        return Kaminari.paginate_array([]) if query.blank?

        strong_memoize(:commits) do
          options = {
            additional_filter: repository_filter
          }

          Repository.find_commits_by_message_with_elastic(
            query,
            page: (page || 1).to_i,
            per_page: per_page,
            options: options
          )
        end
      end

      def wiki_filter
        blob_filter(:wiki, visible_for_guests: true)
      end

      def repository_filter
        blob_filter(:repository)
      end

      def blob_filter(feature, visible_for_guests: false)
        project_ids = visible_for_guests ? limit_project_ids : non_guest_project_ids
        key_name = "#{feature}_access_level"

        conditions =
          if project_ids == :any
            [{ exists: { field: "id" } }]
          else
            project_ids = Project
              .id_in(project_ids)
              .filter_by_feature_visibility(feature, current_user)
              .pluck_primary_key

            [{ terms: { id: project_ids } }]
          end

        if public_and_internal_projects
          conditions << {
                          bool: {
                            filter: [
                              { term: { visibility_level: Project::PUBLIC } },
                              { term: { key_name => ProjectFeature::ENABLED } }
                            ]
                          }
                        }

          if current_user && !current_user.external?
            conditions << {
                            bool: {
                              filter: [
                                { term: { visibility_level: Project::INTERNAL } },
                                { term: { key_name => ProjectFeature::ENABLED } }
                              ]
                            }
                          }
          end
        end

        {
          has_parent: {
            parent_type: 'project',
            query: {
              bool: {
                should: conditions,
                must_not: { term: { key_name => ProjectFeature::DISABLED } }
              }
            }
          }
        }
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def guest_project_ids
        if current_user
          current_user.authorized_projects
            .where('project_authorizations.access_level = ?', Gitlab::Access::GUEST)
            .pluck(:id)
        else
          []
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def non_guest_project_ids
        if limit_project_ids == :any
          :any
        else
          @non_guest_project_ids ||= limit_project_ids - guest_project_ids
        end
      end

      def default_scope
        'projects'
      end

      def per_page
        20
      end
    end
  end
end
