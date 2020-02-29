# frozen_string_literal: true

module EE
  module API
    module Entities
      class FeatureFlag < Grape::Entity
        class DetailedScope < Scope
          expose :name
        end
      end
    end
  end
end
