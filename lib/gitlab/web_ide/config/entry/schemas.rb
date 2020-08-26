# frozen_string_literal: true

module Gitlab
  module WebIde
    class Config
      module Entry
        ##
        # Entry that represents a concrete CI/CD job.
        #
        class Terminal < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS = %i[uri match].freeze

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :uri, string

            with_options allow_nil: true do
              validates :match, array_of_strings: true
            end
          end

          def value
            to_hash.compact
          end

          private

          def to_hash
            { uri: uri_value,
              match: match_value || [] }
          end
        end
      end
    end
  end
end


