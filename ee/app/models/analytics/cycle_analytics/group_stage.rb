# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class GroupStage < ApplicationRecord
      belongs_to :group
    end
  end
end
