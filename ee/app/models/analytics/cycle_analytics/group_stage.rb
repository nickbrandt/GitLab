# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class GroupStage < ApplicationRecord
      include Analytics::CycleAnalytics::Stage

      validates :group, presence: true
      belongs_to :group

      alias_attribute :parent, :group
      alias_attribute :parent_id, :group_id
    end
  end
end
