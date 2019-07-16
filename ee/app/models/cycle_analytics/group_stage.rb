# frozen_string_literal: true

module CycleAnalytics
  class GroupStage < ApplicationRecord
    include CycleAnalytics::Stage

    belongs_to :group

    def self.relative_positioning_query_base(stage)
      where(group_id: stage.group_id)
    end

    def self.relative_positioning_parent_column
      :group_id
    end

    def parent
      group
    end
  end
end
