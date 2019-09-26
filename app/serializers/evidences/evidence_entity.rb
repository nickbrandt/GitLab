# frozen_string_literal: true

module Evidences
  class EvidenceEntity < Grape::Entity
    expose :release, using: ReleaseEntity
  end
end
