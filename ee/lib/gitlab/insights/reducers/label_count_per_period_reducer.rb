# frozen_string_literal: true

module Gitlab
  module Insights
    module Reducers
      # #reduce returns a hash { period => { label1: issuable_count } }, e.g.
      #   {
      #     'January 2019' => {
      #       'Manage' => 2,
      #       'Plan' => 3,
      #       'undefined' => 1
      #     },
      #     'February 2019' => {
      #       'Manage' => 1,
      #       'Plan' => 2,
      #       'undefined' => 0
      #     }
      #   }
      class LabelCountPerPeriodReducer < CountPerPeriodReducer
        def initialize(issuables, labels:, period:, period_limit:, period_field: :created_at)
          super(issuables, period: period, period_limit: period_limit, period_field: period_field)
          @labels = labels
        end

        private

        attr_reader :labels

        # Returns a hash { label => issuables_count }, e.g.
        #   {
        #     'Manage' => 2,
        #     'Plan' => 3,
        #     'undefined' => 1
        #   }
        def value_for_period(issuables)
          Gitlab::Insights::Reducers::CountPerLabelReducer.reduce(issuables, labels: labels)
        end
      end
    end
  end
end
