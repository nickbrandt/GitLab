# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of release:assets:links.
        #
        class Links < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Validatable

          entry :link, Entry::Link, description: 'Release assets:links:link.'

          validations do
            validates :config, type: Array, presence: true
          end

          def skip_config_hash_validation?
            true
          end
        end
      end
    end
  end
end
