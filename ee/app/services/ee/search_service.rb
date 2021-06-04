# frozen_string_literal: true

module EE
  module SearchService
    extend ::Gitlab::Utils::Override

    # This is a proper method instead of a `delegate` in order to
    # avoid adding unnecessary methods to Search::SnippetService
    def use_elasticsearch?
      search_service.use_elasticsearch?
    end

    def valid_query_length?
      return true if use_elasticsearch?

      super
    end

    def valid_terms_count?
      return true if use_elasticsearch?

      super
    end

    def show_epics?
      search_service.allowed_scopes.include?('epics')
    end

    def show_elasticsearch_tabs?
      ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: search_service.elasticsearchable_scope)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    # rubocop: disable Gitlab/ModuleWithInstanceVariables
    def projects
      return @projects if defined?(@projects)

      @projects =
        if params[:project_ids].present?
          project_ids = params[:project_ids].split(',')
          the_projects = ::Project.where(id: project_ids)
          allowed_projects = the_projects.find_all { |p| can?(current_user, :read_project, p) }
          allowed_projects.presence
        else
          nil
        end
    end
    # rubocop: enable Gitlab/ModuleWithInstanceVariables
    # rubocop: enable CodeReuse/ActiveRecord

    private

    override :search_service
    def search_service
      return super if group.blank? || projects.blank?
      raise "[search_service]"
      return super unless ::Feature.enabled?(:advanced_search_multi_project_select, group)
      return super unless ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: group) || ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: projects)

      @search_service ||= ::Search::ProjectService.new(projects, current_user, params) # rubocop: disable Gitlab/ModuleWithInstanceVariables
    end
  end
end
