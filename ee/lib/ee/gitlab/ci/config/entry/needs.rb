# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          ##
          # Entry that represents a cross-project needs dependency.
          #
          class Needs < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable
            include ::Gitlab::Config::Entry::Attributable

            ALLOWED_KEYS = %i[pipeline].freeze
            attributes :pipeline

            validations do
              validates :config, presence: true
              validates :config, allowed_keys: ALLOWED_KEYS
              validates :pipeline, type: String, presence: true
            end
          end
        end
      end
    end
  end
end
