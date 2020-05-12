# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Secrets
          class Vault
            ##
            # Entry that represents Vault secret.
            #
            class Secret < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Configurable
              include ::Gitlab::Config::Entry::Attributable

              ALLOWED_KEYS = %i[engine path fields strategy].freeze

              attributes ALLOWED_KEYS

              entry :engine, Entry::Secrets::Vault::Engine, description: 'Vault secrets engine configuration'

              validations do
                validates :config, type: Hash, allowed_keys: ALLOWED_KEYS
                validates :path, presence: true, type: String
                validates :fields, presence: true, array_of_strings: true

                validates :strategy, presence: true, allowed_values: ['read']
                validates :engine, presence: true, type: Hash
              end

              def value
                {
                  engine: engine_value,
                  path: path,
                  fields: fields,
                  strategy: strategy
                }
              end
            end
          end
        end
      end
    end
  end
end
