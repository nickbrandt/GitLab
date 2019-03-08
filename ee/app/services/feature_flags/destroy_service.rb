# frozen_string_literal: true

module FeatureFlags
  class DestroyService < FeatureFlags::BaseService
    def execute(feature_flag)
      ActiveRecord::Base.transaction do
        if feature_flag.destroy
          save_audit_event(audit_event(feature_flag))

          success(feature_flag: feature_flag)
        else
          error(feature_flag.errors.full_messages)
        end
      end
    end

    private

    def audit_message(feature_flag)
      "Deleted feature flag <strong>#{feature_flag.name}</strong>."
    end
  end
end
