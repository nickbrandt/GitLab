# frozen_string_literal: true

module EE
  module Search
    module ProjectService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        if ::Gitlab::CurrentSettings.elasticsearch_search?
          ::Gitlab::Elastic::ProjectSearchResults.new(current_user,
                                                    params[:search],
                                                    project.id,
                                                    params[:repository_ref])
        else
          super
        end
      end
    end
  end
end
