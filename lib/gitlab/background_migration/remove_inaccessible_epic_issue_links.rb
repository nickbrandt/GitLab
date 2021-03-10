# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop:disable Style/Documentation
    class RemoveInaccessibleEpicIssueLinks
      def perform(group_ids)
      end
    end
  end
end

Gitlab::BackgroundMigration::RemoveInaccessibleEpicIssueLinks.prepend_if_ee('EE::Gitlab::BackgroundMigration::RemoveInaccessibleEpicIssueLinks')
