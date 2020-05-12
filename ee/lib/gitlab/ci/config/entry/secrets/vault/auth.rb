# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Secrets
          class Vault
            ##
            # Entry that represents Vault auth configuration.
            #
            class Auth < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Validatable
              include ::Gitlab::Config::Entry::Attributable

              ALLOWED_KEYS = %i[name path data].freeze

              attributes ALLOWED_KEYS

              validations do
                validates :config, type: Hash, allowed_keys: ALLOWED_KEYS
                validates :name, type: String
                validates :path, type: String
                validates :data, type: Hash
              end
            end
          end
        end
      end
    end
  end
end
