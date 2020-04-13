# frozen_string_literal: true

module EE
  module API
    module Entities
      module Nuget
        class ServiceIndex < Grape::Entity
          expose :version
          expose :resources
        end
      end
    end
  end
end
