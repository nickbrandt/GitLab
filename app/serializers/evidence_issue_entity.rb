# frozen_string_literal: true

class EvidenceIssueEntity < Grape::Entity
  expose :id
  expose :title
  expose :description
  expose :author, using: EvidenceAuthorEntity
  expose :state
  expose :iid
  expose :confidential
  expose :created_at
  expose :due_date
end
