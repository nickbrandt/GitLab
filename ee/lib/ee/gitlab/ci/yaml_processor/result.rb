# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module YamlProcessor
        module Result
          extend ::Gitlab::Utils::Override

          override :build_attributes
          def build_attributes(name)
            job = jobs.fetch(name.to_sym, {})

            super.deep_merge(
              options: { dast_configuration: job[:dast_configuration] }.compact
            )
          end
        end
      end
    end
  end
end
