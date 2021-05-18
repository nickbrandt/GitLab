# frozen_string_literal: true

module Ci
  class PendingBuild < ApplicationRecord
    extend Gitlab::Ci::Model

    belongs_to :project
    belongs_to :build, class_name: 'Ci::Build', inverse_of: :queuing_entry

    def self.upsert!(build)
      entry = self.new(build: build, project: build.project)

      raise ArgumentError, 'queuing entry invalid' unless entry.valid?

      upsert({ build_id: entry.build_id, project_id: entry.project_id })
    end
  end
end
