# frozen_string_literal: true

module EE
  module Ci
    module PipelineEnums
      extend ActiveSupport::Concern

      class_methods do
        extend ::Gitlab::Utils::Override

        override :failure_reasons
        def failure_reasons
          super.merge(activity_limit_exceeded: 20, size_limit_exceeded: 21)
        end

        override :sources
        def sources
          super.merge(pipeline: 7, webide: 9)
        end

        override :config_sources
        def config_sources
          super.merge(webide_source: 3)
        end
      end
    end
  end
end
