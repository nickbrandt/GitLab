# frozen_string_literal: true

module CycleAnalytics
  class ProjectStage < ApplicationRecord
    include CycleAnalytics::Stage

    belongs_to :project

    alias_attribute :parent, :project

    def self.relative_positioning_query_base(stage)
      where(project_id: stage.project_id)
    end

    def self.relative_positioning_parent_column
      :project_id
    end
  end
end
