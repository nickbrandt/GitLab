# frozen_string_literal: true

module Quality
  module Seeders
    module Insights
      class Issues < Seeders::Issues
        TEAM_LABELS = %w[Plan Create Manage Verify Secure].freeze
        TYPE_LABELS = %w[bug feature].freeze
        SEVERITY_LABELS = %w[S::1 S::2 S::3 S::4].freeze
        PRIORITY_LABELS = %w[P::1 P::2 P::3 P::4].freeze

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
