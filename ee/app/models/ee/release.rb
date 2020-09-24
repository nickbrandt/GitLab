# frozen_string_literal: true

module EE
  module Release
    extend ActiveSupport::Concern

    prepended do
      include UsageStatistics

      belongs_to :milestone, optional: true
    end
  end
end
