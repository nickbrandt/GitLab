# frozen_string_literal: true

module EpicIssues
  class ListService < IssuableLinks::ListService
    extend ::Gitlab::Utils::Override

    private

    def child_issuables
      return [] unless issuable&.group&.feature_available?(:epics)

      issuable.issues_readable_by(current_user, preload: preload_for_collection)
    end

    override :serializer
    def serializer
      LinkedEpicIssueSerializer
    end
  end
end
