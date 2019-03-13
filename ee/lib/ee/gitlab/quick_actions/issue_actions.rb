# frozen_string_literal: true

module EE
  module Gitlab
    module QuickActions
      module IssueActions
        extend ActiveSupport::Concern
        include ::Gitlab::QuickActions::Dsl

        included do
          desc 'Add to epic'
          explanation 'Adds an issue to an epic.'
          types Issue
          condition do
            quick_action_target.project.group&.feature_available?(:epics) &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
          end
          params '<&epic | group&epic | Epic URL>'
          command :epic do |epic_param|
            @updates[:epic] = extract_epic(epic_param)
          end

          desc 'Remove from epic'
          explanation 'Removes an issue from an epic.'
          types Issue
          condition do
            quick_action_target.persisted? &&
              quick_action_target.project.group&.feature_available?(:epics) &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
          end
          command :remove_epic do
            @updates[:epic] = nil
          end

          desc 'Promote issue to an epic'
          explanation 'Promote issue to an epic.'
          warning 'may expose confidential information'
          types Issue
          condition do
            quick_action_target.persisted? &&
              current_user.can?(:admin_issue, project) &&
              current_user.can?(:create_epic, project.group)
          end
          command :promote do
            Epics::IssuePromoteService.new(quick_action_target.project, current_user).execute(quick_action_target)
          end

          def extract_epic(params)
            return if params.nil?

            extract_references(params, :epic).first
          end
        end
      end
    end
  end
end
