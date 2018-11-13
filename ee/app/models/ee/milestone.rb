# frozen_string_literal: true

module EE
  module Milestone
    extend ActiveSupport::Concern

    prepended do
      include Elastic::MilestonesSearch

      has_many :boards
    end

    def supports_weight?
      parent&.feature_available?(:issue_weights)
    end

    def supports_burndown_charts?
      feature_name = group_milestone? ? :group_burndown_charts : :burndown_charts

      parent&.feature_available?(feature_name) && supports_weight?
    end
  end
end
