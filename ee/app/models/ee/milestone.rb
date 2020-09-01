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

    def supports_milestone_charts?
      resource_parent&.feature_available?(:milestone_charts) && supports_weight?
    end

    def burnup_charts_available?
      ::Feature.enabled?(:burnup_charts, resource_parent)
    end
  end
end
