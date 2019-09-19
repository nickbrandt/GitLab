# frozen_string_literal: true

class EvidenceProjectEntity < Grape::Entity
  expose :id
  expose :name
  expose :description
  expose :created_at
end
