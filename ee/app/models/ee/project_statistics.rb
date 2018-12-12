# frozen_string_literal: true

module EE
  module ProjectStatistics
    def shared_runners_minutes
      shared_runners_seconds.to_i / 60
    end
  end
end
