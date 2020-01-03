# frozen_string_literal: true

module EE
  module WeightEventable
    extend ActiveSupport::Concern

    included do
      has_many :resource_weight_events
    end
  end
end
