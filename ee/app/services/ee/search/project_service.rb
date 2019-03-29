# frozen_string_literal: true

module EE
  module Search
    module ProjectService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        if use_elasticsearch?
          ::Gitlab::Elastic::ProjectSearchResults.new(current_user,
                                                    params[:search],
                                                    project.id,
                                                    params[:repository_ref])
        else
          super
        end
      end

      # This method is used in the top-level SearchService, so cannot be in-lined into #execute
      def use_elasticsearch?
        project.use_elasticsearch?
      end
    end
  end
end
