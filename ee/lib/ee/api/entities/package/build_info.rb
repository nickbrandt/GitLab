# frozen_string_literal: true

module EE
  module API
    module Entities
      class Package < Grape::Entity
        class BuildInfo < Grape::Entity
          expose :pipeline, using: ::API::Entities::PipelineBasic
        end
      end
    end
  end
end
