# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      # This is named ConfigEE to avoid collisions with the
      # EE::Gitlab::Ci::Config namespace
      module ConfigEE
        extend ::Gitlab::Utils::Override

        override :rescue_errors
        def rescue_errors
          [*super, ::Gitlab::Ci::Config::Required::Processor::RequiredError]
        end

        override :build_config
        def build_config(config)
          process_required_includes(super)
        end

        def process_required_includes(config)
          ::Gitlab::Ci::Config::Required::Processor.new(config).perform
        end
      end
    end
  end
end
