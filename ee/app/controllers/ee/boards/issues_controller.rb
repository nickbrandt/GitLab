# frozen_string_literal: true

module EE
  module Boards
    module IssuesController
      extend ::Gitlab::Utils::Override

      override :associations_to_preload
      def associations_to_preload
        super << { target_issue_links: { source: { project: :project_feature } } }
      end
    end
  end
end
