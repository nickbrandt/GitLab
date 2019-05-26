# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        extend ::Gitlab::Utils::Override

        override :rescue_errors
        def rescue_errors
          [*super, ::Gitlab::Ci::Config::Required::Processor::RequiredError]
        end

        override :build_config
        def build_config(config, project:, sha:, user:)
          process_required_includes(super)
        end

        def process_required_includes(config)
          ::Gitlab::Ci::Config::Required::Processor.new(config).perform
        end
      end
    end
  end
end
