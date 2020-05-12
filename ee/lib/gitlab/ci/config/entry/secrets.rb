# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a secrets definition.
        #
        class Secrets < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS = %i[vault].freeze

          attributes ALLOWED_KEYS

          entry :vault, Entry::Secrets::Vault, description: 'Secrets managed by Vault'

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
            validates :vault, type: Hash, allow_nil: true
          end
        end
      end
    end
  end
end
