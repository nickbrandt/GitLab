# frozen_string_literal: true

module Ci
  class PendingBuild < ApplicationRecord
    extend Gitlab::Ci::Model

    belongs_to :project
    belongs_to :build, class_name: 'Ci::Build'

    def self.upsert!(build)
      entry = self.new(build: build, project: build.project)

      raise ArgumentError, 'queuing entry invalid' unless entry.valid?

      attributes = { build_id: entry.build_id, project_id: entry.project_id }

      ActiveRecord::InsertAll
        .new(self, [attributes], on_duplicate: :skip, returning: %w[build_id])
        .execute
    end
  end
end
