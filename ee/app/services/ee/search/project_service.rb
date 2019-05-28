# frozen_string_literal: true

module EE
  module Search
    module ProjectService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        return super unless use_elasticsearch?

        ::Gitlab::Elastic::ProjectSearchResults.new(
          current_user,
          params[:search],
          project.id,
          params[:repository_ref]
        )
      end

      # This method is used in the top-level SearchService, so cannot be in-lined into #execute
      def use_elasticsearch?
        ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: project)
      end
    end
  end
end
