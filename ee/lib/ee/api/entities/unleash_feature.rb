# frozen_string_literal: true

module EE
  module API
    module Entities
      class UnleashFeature < Grape::Entity
        expose :name
        expose :description, unless: ->(feature) { feature.description.nil? }
        expose :active, as: :enabled
        expose :strategies, using: UnleashStrategy
      end
    end
  end
end
