# frozen_string_literal: true

module Gitlab
  module Elastic
    # Always prefer to use the full class namespace when specifying a
    # superclass inside a module, because autoloading can occur in a
    # different order between execution environments.
    class ProjectSearchResults < Gitlab::Elastic::SearchResults
      attr_reader :project, :repository_ref

      delegate :users, to: :generic_search_results
      delegate :limited_users_count, to: :generic_search_results

      def initialize(current_user, query, project_id, repository_ref = nil)
        @current_user = current_user
        @project = Project.find(project_id)
        @repository_ref = repository_ref.presence || project.default_branch
        @query = query
        @public_and_internal_projects = false
      end

      def objects(scope, page = nil)
        case scope
        when 'notes'
          notes.page(page).per(per_page).records
        when 'blobs'
          blobs.page(page).per(per_page)
        when 'wiki_blobs'
          wiki_blobs.page(page).per(per_page)
        when 'commits'
          commits(page: page, per_page: per_page)
        when 'users'
          users.page(page).per(per_page)
        else
          super
        end
      end

      def generic_search_results
        @generic_search_results ||= Gitlab::ProjectSearchResults.new(current_user, project, query, repository_ref)
      end

      private

      def blobs
        return Kaminari.paginate_array([]) unless Ability.allowed?(@current_user, :download_code, project)

        if project.empty_repo? || query.blank?
          Kaminari.paginate_array([])
        else
          # We use elastic for default branch only
          if root_ref?
            project.repository.elastic_search(
              query,
              type: :blob,
              options: { highlight: true }
            )[:blobs][:results].response
          else
            Kaminari.paginate_array(
              Gitlab::FileFinder.new(project, repository_ref).find(query)
            )
          end
        end
      end

      def wiki_blobs
        return Kaminari.paginate_array([]) unless Ability.allowed?(@current_user, :read_wiki, project)

        if project.wiki_enabled? && !project.wiki.empty? && query.present?
          project.wiki.elastic_search(
            query,
            type: :wiki_blob,
            options: { highlight: true }
          )[:wiki_blobs][:results].response
        else
          Kaminari.paginate_array([])
        end
      end

      def notes
        opt = {
          project_ids: limit_project_ids,
          current_user: @current_user,
          public_and_internal_projects: @public_and_internal_projects
        }

        Note.elastic_search(query, options: opt)
      end

      def commits(page: 1, per_page: 20)
        return Kaminari.paginate_array([]) unless Ability.allowed?(@current_user, :download_code, project)

        if project.empty_repo? || query.blank?
          Kaminari.paginate_array([])
        else
          # We use elastic for default branch only
          if root_ref?
            project.repository.find_commits_by_message_with_elastic(
              query,
              page: (page || 1).to_i,
              per_page: per_page
            )
          else
            offset = per_page * ((page || 1) - 1)

            Kaminari.paginate_array(
              project.repository.find_commits_by_message(query),
              offset: offset,
              limit: per_page
            )
          end
        end
      end

      def limit_project_ids
        [project.id]
      end

      def root_ref?
        project.root_ref?(repository_ref)
      end
    end
  end
end
