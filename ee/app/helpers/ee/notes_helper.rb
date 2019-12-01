# frozen_string_literal: true

module EE
  module NotesHelper
    extend ::Gitlab::Utils::Override

    override :notes_url
    def notes_url(params = {})
      return group_epic_notes_path(@epic.group, @epic) if @epic.is_a?(Epic)

      super
    end

    override :discussions_path
    def discussions_path(issuable)
      return discussions_group_epic_path(issuable.group, issuable, format: :json) if issuable.is_a?(Epic)

      super
    end

    override :notes_data
    def notes_data(issuable)
      data = super

      if issuable.is_a?(MergeRequest)
        data.merge!(
          draftsPath: project_merge_request_drafts_path(@project, issuable),
          draftsPublishPath: publish_project_merge_request_drafts_path(@project, issuable),
          draftsDiscardPath: discard_project_merge_request_drafts_path(@project, issuable)
        )
      end

      data
    end

    def description_diff_path(issuable, version_id)
      case issuable
      when Issue
        description_diff_project_issue_path(issuable.project, issuable, version_id)
      when MergeRequest
        description_diff_project_merge_request_path(issuable.project, issuable, version_id)
      when Epic
        description_diff_group_epic_path(issuable.group, issuable, version_id)
      end
    end
  end
end
