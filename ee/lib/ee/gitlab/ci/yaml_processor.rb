# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module YamlProcessor
        extend ::Gitlab::Utils::Override

        override :build_attributes
        def build_attributes(name)
          job = jobs.fetch(name.to_sym, {})
          secrets = job[:secrets]

          super.tap do |attributes|
            attributes[:options][:secrets] = secrets if secrets
          end
        end
      end
    end
  end
end
