# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Secrets
          class Vault
            ##
            # Entry that represents Vault server.
            #
            class Server < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Configurable
              include ::Gitlab::Config::Entry::Attributable

              ALLOWED_KEYS = %i[url auth secrets].freeze

              attributes ALLOWED_KEYS

              entry :auth, Entry::Secrets::Vault::Auth, description: 'Vault auth configuration'
              entry :secrets, Entry::Secrets::Vault::Secrets, description: 'Vault secrets for a job'

              validations do
                validates :config, type: Hash, allowed_keys: ALLOWED_KEYS
                validates :url, presence: true, addressable_url: true
                validates :secrets, type: Hash
                validates :auth, type: Hash
              end

              def value
                {
                  url: url,
                  auth: auth_value,
                  secrets: secrets_value
                }
              end
            end
          end
        end
      end
    end
  end
end
