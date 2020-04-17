# frozen_string_literal: true

module EE
  module Milestone
    extend ActiveSupport::Concern

    prepended do
      include Elastic::ApplicationVersionedSearch

      has_many :boards
    end

    def supports_weight?
      resource_parent&.feature_available?(:issue_weights)
    end

    def supports_burndown_charts?
      feature_name = group_milestone? ? :group_burndown_charts : :burndown_charts

      resource_parent&.feature_available?(feature_name) && supports_weight?
    end

    def burnup_charts_available?
      ::Feature.enabled?(:burnup_charts, resource_parent)
    end
  end
end
