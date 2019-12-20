# frozen_string_literal: true

module EE
  module Gitlab
    module QuickActions
      module IssueActions
        extend ActiveSupport::Concern
        include ::Gitlab::QuickActions::Dsl

        included do
          desc _('Add to epic')
          explanation _('Adds an issue to an epic.')
          types Issue
          condition do
            quick_action_target.project.group&.feature_available?(:epics) &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
          end
          params '<&epic | group&epic | Epic URL>'
          command :epic do |epic_param|
            epic = extract_epic(epic_param)
            issue = quick_action_target

            message =
              if epic && current_user.can?(:read_epic, epic)
                if issue&.epic == epic
                  _('Issue %{issue_reference} has already been added to epic %{epic_reference}.') %
                    { issue_reference: issue.to_reference, epic_reference: epic.to_reference }
                else
                  @updates[:epic] = epic
                  _('Added an issue to an epic.')
                end
              else
                _("This epic does not exist or you don't have sufficient permission.")
              end

            @execution_message[:epic] = message
          end

          desc _('Remove from epic')
          explanation _('Removes an issue from an epic.')
          execution_message _('Removed an issue from an epic.')
          types Issue
          condition do
            quick_action_target.persisted? &&
              quick_action_target.project.group&.feature_available?(:epics) &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
          end
          command :remove_epic do
            @updates[:epic] = nil
          end

          promote_message = _('Promote issue to an epic')
          promote_message_confidential = _('Promote confidential issue to a non-confidential epic')

          desc do
            if quick_action_target.confidential?
              promote_message_confidential
            else
              promote_message
            end
          end
          explanation promote_message
          warning do
            if quick_action_target.confidential?
              promote_message_confidential
            end
          end
          icon 'confidential'
          types Issue
          condition do
            quick_action_target.persisted? &&
              current_user.can?(:admin_issue, project) &&
              current_user.can?(:create_epic, project.group)
          end
          command :promote do
            Epics::IssuePromoteService.new(quick_action_target.project, current_user).execute(quick_action_target)

            @execution_message[:promote] = if quick_action_target.confidential?
                                             _('Promoted confidential issue to a non-confidential epic. Information in this issue is no longer confidential as epics are public to group members.')
                                           else
                                             _('Promoted issue to an epic.')
                                           end
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
