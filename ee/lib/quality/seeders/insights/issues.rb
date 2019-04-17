# frozen_string_literal: true

module Quality
  module Seeders
    module Insights
      class Issues < Seeders::Issues
        TEAM_LABELS = %w[Plan Create Manage Verify Secure].freeze
        TYPE_LABELS = %w[bug feature].freeze
        SEVERITY_LABELS = %w[severity::1 severity::2 severity::3 severity::4].freeze
        PRIORITY_LABELS = %w[priority::1 priority::2 priority::3 priority::4].freeze

        private

        def labels
          super + [
            TEAM_LABELS.sample,
            TYPE_LABELS.sample,
            SEVERITY_LABELS.sample,
            PRIORITY_LABELS.sample
          ]
        end
      end
    end
  end
end
