# frozen_string_literal: true

module EE
  module API
    module Entities
      class FeatureFlag < Grape::Entity
        class Scope < Grape::Entity
          expose :id
          expose :active
          expose :environment_scope
          expose :strategies
          expose :created_at
          expose :updated_at
        end

        class DetailedScope < Scope
          expose :name
        end

        expose :name
        expose :description
        expose :created_at
        expose :updated_at
        expose :scopes, using: Scope
      end
    end
  end
end
