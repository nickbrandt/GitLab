# frozen_string_literal: true

module EE
  module Boards
    module IssuesController
      extend ::Gitlab::Utils::Override

      override :associations_to_preload
      def associations_to_preload
        super << { blocked_by_issues: { project: :project_feature } }
      end
    end
  end
end
