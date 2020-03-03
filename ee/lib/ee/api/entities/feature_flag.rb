# frozen_string_literal: true

module EE
  module API
    module Entities
      class FeatureFlag < Grape::Entity
        expose :name
        expose :description
        expose :created_at
        expose :updated_at
        expose :scopes, using: FeatureFlag::Scope
      end
    end
  end
end
