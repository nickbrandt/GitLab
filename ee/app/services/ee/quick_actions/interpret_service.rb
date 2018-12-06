# frozen_string_literal: true

module EE
  module QuickActions
    module InterpretService
      extend ActiveSupport::Concern

      # We use "prepended" here instead of including Gitlab::QuickActions::Dsl,
      # as doing so would clear any existing command definitions.
      prepended do
        desc 'Change assignee(s)'
        explanation do
          'Change assignee(s)'
        end
        params '@user1 @user2'
        condition do
          issuable.is_a?(::Issuable) &&
            issuable.allows_multiple_assignees? &&
            issuable.persisted? &&
            current_user.can?(:"admin_#{issuable.to_ability_name}", project)
        end
        command :reassign do |reassign_param|
          @updates[:assignee_ids] = extract_users(reassign_param).map(&:id)
        end

        desc 'Set weight'
        explanation do |weight|
          "Sets weight to #{weight}." if weight
        end
        params "0, 1, 2, …"
        condition do
          issuable.is_a?(::Issuable) &&
            issuable.supports_weight? &&
            current_user.can?(:"admin_#{issuable.to_ability_name}", issuable)
        end
        parse_params do |weight|
          weight.to_i if weight.to_i > 0
        end
        command :weight do |weight|
          @updates[:weight] = weight if weight
        end

        desc 'Clear weight'
        explanation 'Clears weight.'
        condition do
          issuable.is_a?(::Issuable) &&
            issuable.persisted? &&
            issuable.supports_weight? &&
            issuable.weight? &&
            current_user.can?(:"admin_#{issuable.to_ability_name}", issuable)
        end
        command :clear_weight do
          @updates[:weight] = nil
        end

        desc 'Add to epic'
        explanation 'Adds an issue to an epic.'
        condition do
          issuable.is_a?(::Issue) &&
            issuable.project.group&.feature_available?(:epics) &&
            current_user.can?(:"admin_#{issuable.to_ability_name}", issuable)
        end
        params '<&epic | group&epic | Epic URL>'
        command :epic do |epic_param|
          @updates[:epic] = extract_epic(epic_param)
        end

        desc 'Remove from epic'
        explanation 'Removes an issue from an epic.'
        condition do
          issuable.is_a?(::Issue) &&
            issuable.persisted? &&
            issuable.project.group&.feature_available?(:epics) &&
            current_user.can?(:"admin_#{issuable.to_ability_name}", issuable)
        end
        command :remove_epic do
          @updates[:epic] = nil
        end

        desc 'Approve a merge request'
        explanation 'Approve the current merge request'
        condition do
          issuable.is_a?(MergeRequest) && issuable.persisted? && issuable.can_approve?(current_user)
        end
        command :approve do
          if issuable.can_approve?(current_user)
            ::MergeRequests::ApprovalService.new(issuable.project, current_user).execute(issuable)
          end
        end

        desc 'Promote issue to an epic'
        explanation 'Promote issue to an epic'
        warning 'may expose confidential information'
        condition do
          issuable.is_a?(Issue) &&
            issuable.persisted? &&
            current_user.can?(:admin_issue, project) &&
            current_user.can?(:create_epic, project.group)
        end
        command :promote do
          Epics::IssuePromoteService.new(issuable.project, current_user).execute(issuable)
        end
      end

      def extract_epic(params)
        return nil if params.nil?

        extract_references(params, :epic).first
      end
    end
  end
end
