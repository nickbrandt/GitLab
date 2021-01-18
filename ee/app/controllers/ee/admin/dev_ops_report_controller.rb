# frozen_string_literal: true

module EE
  module Admin
    module DevOpsReportController
      def show_adoption?
        feature_already_in_use = ::Analytics::DevopsAdoption::Segment.any?

        ::License.feature_available?(:devops_adoption) &&
          ::Feature.enabled?(:devops_adoption_feature, default_enabled: feature_already_in_use)
      end
    end
  end
end
