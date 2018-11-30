# frozen_string_literal: true

module EE
  module UserCalloutEnums
    extend ActiveSupport::Concern

    class_methods do
      extend ::Gitlab::Utils::Override

      override :feature_names
      def feature_names
        super.merge(cluster_security_warning: 3, gold_trial: 4)
      end
    end
  end
end
