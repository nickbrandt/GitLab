# frozen_string_literal: true

module EE
  module IdeController
    extend ActiveSupport::Concern

    prepended do
      before_action do
        push_frontend_feature_flag(:build_service_proxy)
      end
    end
  end
end
