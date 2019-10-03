# frozen_string_literal: true

module EE
  # Project EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Deployment` model
  module Deployment
    extend ActiveSupport::Concern

    prepended do
      include UsageStatistics
    end
  end
end
