# frozen_string_literal: true

class EvidenceAuthorEntity < Grape::Entity
  expose :id
  expose :name
  expose :email
end
