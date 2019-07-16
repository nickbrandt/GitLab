# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module StageEvents
      ENUM_MAPPING = {
        StageEvents::IssueClosed => 1,
        StageEvents::IssueCreated => 2,
        StageEvents::IssueFirstAddedToBoard => 3,
        StageEvents::IssueFirstAssociatedWithMilestone => 4,
        StageEvents::IssueFirstMentionedInCommit => 5,
        StageEvents::IssueLabelAdded => 6,
        StageEvents::IssueLabelRemoved => 7,
        StageEvents::IssueLastEdited => 8,
        StageEvents::MergeRequestClosed => 100,
        StageEvents::MergeRequestCreated => 101,
        StageEvents::MergeRequestFirstDeployedToProduction => 102,
        StageEvents::MergeRequestLabelAdded => 103,
        StageEvents::MergeRequestLabelRemoved => 104,
        StageEvents::MergeRequestLastBuildFinished => 105,
        StageEvents::MergeRequestLastBuildStarted => 106,
        StageEvents::MergeRequestLastEdited => 107,
        StageEvents::MergeRequestMerged => 108,
        StageEvents::CodeStageStart => 1001,
        StageEvents::IssueStageEnd => 1002,
        StageEvents::PlanStageStart => 1003
      }.freeze

      EVENTS = ENUM_MAPPING.keys.freeze

      PAIRING_RULES = {
        StageEvents::PlanStageStart => [
          StageEvents::IssueFirstMentionedInCommit
        ],
        StageEvents::CodeStageStart => [
          StageEvents::MergeRequestCreated
        ],
        StageEvents::IssueCreated => [
          StageEvents::IssueClosed,
          StageEvents::IssueFirstAddedToBoard,
          StageEvents::IssueFirstAssociatedWithMilestone,
          StageEvents::IssueFirstMentionedInCommit,
          StageEvents::IssueLabelAdded,
          StageEvents::IssueLabelRemoved,
          StageEvents::IssueLastEdited,
          StageEvents::IssueStageEnd
        ],
        StageEvents::IssueFirstAddedToBoard => [
          StageEvents::IssueClosed,
          StageEvents::IssueFirstAssociatedWithMilestone,
          StageEvents::IssueFirstMentionedInCommit,
          StageEvents::IssueLabelAdded,
          StageEvents::IssueLabelRemoved,
          StageEvents::IssueLastEdited
        ],
        StageEvents::IssueFirstAssociatedWithMilestone => [
          StageEvents::IssueClosed,
          StageEvents::IssueFirstAddedToBoard,
          StageEvents::IssueFirstMentionedInCommit,
          StageEvents::IssueLabelAdded,
          StageEvents::IssueLabelRemoved,
          StageEvents::IssueLastEdited
        ],
        StageEvents::IssueFirstMentionedInCommit => [
          StageEvents::IssueClosed,
          StageEvents::IssueFirstAssociatedWithMilestone,
          StageEvents::IssueFirstAddedToBoard,
          StageEvents::IssueLabelAdded,
          StageEvents::IssueLabelRemoved,
          StageEvents::IssueLastEdited
        ],
        StageEvents::IssueLabelAdded => [
          StageEvents::IssueClosed,
          StageEvents::IssueFirstAddedToBoard,
          StageEvents::IssueFirstAssociatedWithMilestone,
          StageEvents::IssueFirstMentionedInCommit,
          StageEvents::IssueLabelAdded,
          StageEvents::IssueLabelRemoved,
          StageEvents::IssueLastEdited
        ],
        StageEvents::IssueLabelRemoved => [
          StageEvents::IssueClosed,
          StageEvents::IssueFirstAddedToBoard,
          StageEvents::IssueFirstAssociatedWithMilestone,
          StageEvents::IssueFirstMentionedInCommit,
          StageEvents::IssueLabelAdded,
          StageEvents::IssueLabelRemoved,
          StageEvents::IssueLastEdited
        ],
        StageEvents::IssueClosed => [
          StageEvents::IssueLabelAdded,
          StageEvents::IssueLabelRemoved,
          StageEvents::IssueLastEdited
        ],
        StageEvents::MergeRequestCreated => [
          StageEvents::MergeRequestClosed,
          StageEvents::MergeRequestFirstDeployedToProduction,
          StageEvents::MergeRequestLabelAdded,
          StageEvents::MergeRequestLabelRemoved,
          StageEvents::MergeRequestLastBuildStarted,
          StageEvents::MergeRequestLastBuildFinished,
          StageEvents::MergeRequestLastEdited,
          StageEvents::MergeRequestMerged
        ],
        StageEvents::MergeRequestClosed => [
          StageEvents::MergeRequestFirstDeployedToProduction,
          StageEvents::MergeRequestLabelAdded,
          StageEvents::MergeRequestLabelRemoved,
          StageEvents::MergeRequestLastEdited
        ],
        StageEvents::MergeRequestFirstDeployedToProduction => [
          StageEvents::MergeRequestLabelAdded,
          StageEvents::MergeRequestLabelRemoved,
          StageEvents::MergeRequestLastEdited
        ],
        StageEvents::MergeRequestLabelAdded => [
          StageEvents::MergeRequestClosed,
          StageEvents::MergeRequestFirstDeployedToProduction,
          StageEvents::MergeRequestLabelAdded,
          StageEvents::MergeRequestLabelRemoved,
          StageEvents::MergeRequestLastBuildStarted,
          StageEvents::MergeRequestLastBuildFinished,
          StageEvents::MergeRequestLastEdited,
          StageEvents::MergeRequestMerged
        ],
        StageEvents::MergeRequestLabelRemoved => [
          StageEvents::MergeRequestClosed,
          StageEvents::MergeRequestFirstDeployedToProduction,
          StageEvents::MergeRequestLabelAdded,
          StageEvents::MergeRequestLabelRemoved,
          StageEvents::MergeRequestLastBuildStarted,
          StageEvents::MergeRequestLastBuildFinished,
          StageEvents::MergeRequestLastEdited,
          StageEvents::MergeRequestMerged
        ],
        StageEvents::MergeRequestLastBuildStarted => [
          StageEvents::MergeRequestClosed,
          StageEvents::MergeRequestFirstDeployedToProduction,
          StageEvents::MergeRequestLabelAdded,
          StageEvents::MergeRequestLabelRemoved,
          StageEvents::MergeRequestLastBuildFinished,
          StageEvents::MergeRequestLastEdited,
          StageEvents::MergeRequestMerged
        ],
        StageEvents::MergeRequestLastBuildFinished => [
          StageEvents::MergeRequestClosed,
          StageEvents::MergeRequestFirstDeployedToProduction,
          StageEvents::MergeRequestLabelAdded,
          StageEvents::MergeRequestLabelRemoved,
          StageEvents::MergeRequestLastEdited,
          StageEvents::MergeRequestMerged
        ],
        StageEvents::MergeRequestMerged => [
          StageEvents::MergeRequestFirstDeployedToProduction,
          StageEvents::MergeRequestLabelAdded,
          StageEvents::MergeRequestLabelRemoved,
          StageEvents::MergeRequestLastEdited
        ]
      }.freeze

      def [](identifier)
        EVENTS.find { |e| e.identifier.to_s.eql?(identifier.to_s) } || raise(KeyError)
      end

      # hash for AR enum: identifier => number
      def to_enum
        ENUM_MAPPING.each_with_object({}) { |(k, v), hash| hash[k.identifier] = v }
      end

      module_function :[], :to_enum
    end
  end
end
