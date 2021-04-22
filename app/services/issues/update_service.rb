# frozen_string_literal: true

module Issues
  class UpdateService < Issues::BaseService
    extend ::Gitlab::Utils::Override

    def execute(issue)
      handle_move_between_ids(issue)

      @request = params.delete(:request)
      @spam_params = Spam::SpamActionService.filter_spam_params!(params, @request)

      change_issue_duplicate(issue)
      move_issue_to_new_project(issue) || clone_issue(issue) || update_task_event(issue) || update(issue)
    end

    def update(issue)
      create_merge_request_from_quick_action

      super
    end

    override :filter_params
    def filter_params(issue)
      super

      # filter confidential in `Issues::UpdateService` and not in `IssuableBaseService#filtr_params`
      # because we do allow users that cannot admin issues to set confidential flag when creating an issue
      unless can_admin_issuable?(issue)
        params.delete(:confidential)
      end
    end

    def before_update(issue, skip_spam_check: false)
      return if skip_spam_check

      Spam::SpamActionService.new(
        spammable: issue,
        request: request,
        user: current_user,
        action: :update
      ).execute(spam_params: spam_params)
    end

    def after_update(issue)
      IssuesChannel.broadcast_to(issue, event: 'updated') if Gitlab::ActionCable::Config.in_app? || Feature.enabled?(:broadcast_issue_updates, issue.project)
    end

    def handle_changes(issue, options)
      old_associations = options.fetch(:old_associations, {})
      old_labels = old_associations.fetch(:labels, [])
      old_mentioned_users = old_associations.fetch(:mentioned_users, [])
      old_assignees = old_associations.fetch(:assignees, [])

      if has_changes?(issue, old_labels: old_labels, old_assignees: old_assignees)
        todo_service.resolve_todos_for_target(issue, current_user)
      end

      if issue.previous_changes.include?('title') ||
          issue.previous_changes.include?('description')
        todo_service.update_issue(issue, current_user, old_mentioned_users)
      end

      if issue.assignees != old_assignees
        create_assignee_note(issue, old_assignees)
        notification_service.async.reassigned_issue(issue, current_user, old_assignees)
        todo_service.reassigned_assignable(issue, current_user, old_assignees)
        update_assigned_issue_counts(issue.assignees, old_assignees)
        track_incident_action(current_user, issue, :incident_assigned)
      end

      if issue.previous_changes.include?('confidential')
        # don't enqueue immediately to prevent todos removal in case of a mistake
        TodosDestroyer::ConfidentialIssueWorker.perform_in(Todo::WAIT_FOR_DELETE, issue.id) if issue.confidential?
        create_confidentiality_note(issue)
        track_usage_event(:incident_management_incident_change_confidential, current_user.id)
      end

      added_labels = issue.labels - old_labels

      if added_labels.present?
        notification_service.async.relabeled_issue(issue, added_labels, current_user)
      end

      handle_milestone_change(issue)

      added_mentions = issue.mentioned_users(current_user) - old_mentioned_users

      if added_mentions.present?
        notification_service.async.new_mentions_in_issue(issue, added_mentions, current_user)
      end
    end

    def handle_task_changes(issuable)
      todo_service.resolve_todos_for_target(issuable, current_user)
      todo_service.update_issue(issuable, current_user)
    end

    def handle_move_between_ids(issue)
      super

      rebalance_if_needed(issue)
    end

    def positioning_scope_key
      :board_group_id
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def change_issue_duplicate(issue)
      canonical_issue_id = params.delete(:canonical_issue_id)
      return unless canonical_issue_id

      canonical_issue = IssuesFinder.new(current_user).find_by(id: canonical_issue_id)

      if canonical_issue
        Issues::DuplicateService.new(project, current_user).execute(issue, canonical_issue)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def move_issue_to_new_project(issue)
      target_project = params.delete(:target_project)

      return unless target_project &&
          issue.can_move?(current_user, target_project) &&
          target_project != issue.project

      update(issue)
      Issues::MoveService.new(project, current_user).execute(issue, target_project)
    end

    private

    attr_reader :request, :spam_params

    def clone_issue(issue)
      target_project = params.delete(:target_clone_project)
      with_notes = params.delete(:clone_with_notes)

      return unless target_project &&
        issue.can_clone?(current_user, target_project)

      # we've pre-empted this from running in #execute, so let's go ahead and update the Issue now.
      update(issue)
      Issues::CloneService.new(project, current_user).execute(issue, target_project, with_notes: with_notes)
    end

    def create_merge_request_from_quick_action
      create_merge_request_params = params.delete(:create_merge_request)
      return unless create_merge_request_params

      MergeRequests::CreateFromIssueService.new(project, current_user, create_merge_request_params).execute
    end

    def handle_milestone_change(issue)
      return unless issue.previous_changes.include?('milestone_id')

      invalidate_milestone_issue_counters(issue)
      send_milestone_change_notification(issue)
    end

    def invalidate_milestone_issue_counters(issue)
      issue.previous_changes['milestone_id'].each do |milestone_id|
        next unless milestone_id

        milestone = Milestone.find_by_id(milestone_id)

        delete_milestone_closed_issue_counter_cache(milestone)
        delete_milestone_total_issue_counter_cache(milestone)
      end
    end

    def send_milestone_change_notification(issue)
      return if skip_milestone_email

      if issue.milestone.nil?
        notification_service.async.removed_milestone_issue(issue, current_user)
      else
        notification_service.async.changed_milestone_issue(issue, issue.milestone, current_user)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def issuable_for_positioning(id, board_group_id = nil)
      return unless id

      issue =
        if board_group_id
          IssuesFinder.new(current_user, group_id: board_group_id, include_subgroups: true).find_by(id: id)
        else
          project.issues.find(id)
        end

      issue if can?(current_user, :update_issue, issue)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def create_confidentiality_note(issue)
      SystemNoteService.change_issue_confidentiality(issue, issue.project, current_user)
    end

    def update_assigned_issue_counts(current_assignees, old_assignees)
      # union minus intersection gives us all assignees that are being either assigned or unassigned.
      changed_assignees = (current_assignees | old_assignees) - (current_assignees & old_assignees)

      Users::UpdateOpenIssueCountWorker.perform_async(current_user.id, changed_assignees.map(&:id))
    end
  end
end

Issues::UpdateService.prepend_if_ee('EE::Issues::UpdateService')
