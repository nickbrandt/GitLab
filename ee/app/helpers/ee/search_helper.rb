# frozen_string_literal: true
module EE
  module SearchHelper
    extend ::Gitlab::Utils::Override

    def search_filter_input_options(type)
      options = super
      options[:data][:'multiple-assignees'] = 'true' if search_multiple_assignees?(type)

      options
    end

    override :find_project_for_result_blob
    def find_project_for_result_blob(projects, result)
      return super if result.is_a?(::Gitlab::Search::FoundBlob)

      super || projects&.find { |project| project.id == blob_project_id(result) }
    end

    override :blob_projects
    def blob_projects(results)
      return super if results.first.is_a?(::Gitlab::Search::FoundBlob)

      project_ids = results.map(&method(:blob_project_id))

      ::ProjectsFinder.new(current_user: current_user, project_ids_relation: project_ids).execute
    end

    override :parse_search_result
    def parse_search_result(result)
      return super if result.is_a?(::Gitlab::Search::FoundBlob)

      ::Gitlab::Elastic::SearchResults.parse_search_result(result)
    end

    override :search_blob_title
    def search_blob_title(project, file_name)
      if @project
        file_name
      else
        (project.full_name + ': ' + content_tag(:i, file_name)).html_safe
      end
    end

    private

    def search_multiple_assignees?(type)
      context = @project.presence || @group.presence || :dashboard

      type == :issues && (context == :dashboard ||
        context.feature_available?(:multiple_issue_assignees))
    end

    def blob_project_id(blob_result)
      blob_result.dig('_source', 'join_field', 'parent')&.split('_')&.last.to_i
    end
  end
end
