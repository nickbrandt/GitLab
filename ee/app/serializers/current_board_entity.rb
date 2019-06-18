# frozen_string_literal: true

class CurrentBoardEntity < Grape::Entity
  expose :id
  expose :name
  expose :milestone_id
  expose :weight
  expose :label_ids
  expose :milestone, using: BoardMilestoneEntity
  expose :assignee, using: BoardAssigneeEntity
  expose :labels, using: BoardLabelEntity
end
