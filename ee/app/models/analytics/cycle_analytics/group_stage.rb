# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class GroupStage < ApplicationRecord
      include Analytics::CycleAnalytics::Stage

      validates :group, presence: true
      belongs_to :group

      alias_attribute :parent, :group
    end
  end
end
