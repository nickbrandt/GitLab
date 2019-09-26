# frozen_string_literal: true

class EvidenceReleaseEntity < Grape::Entity
  expose :id
  expose :tag, as: :tag_name
  expose :name
  expose :description
  expose :created_at
  expose :project, using: EvidenceProjectEntity
  expose :milestones, using: EvidenceMilestoneEntity
end
