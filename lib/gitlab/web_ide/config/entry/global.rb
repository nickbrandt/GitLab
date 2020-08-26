# frozen_string_literal: true

module Gitlab
  module WebIde
    class Config
      module Entry
        ##
        # This class represents a global entry - root Entry for entire
        # GitLab WebIde Configuration file.
        #
        class Global < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Attributable

          ALLOWED_KEYS = %i[terminal json_schemas yaml_schemas].freeze

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS
          end

          entry :terminal, Entry::Terminal,
            description: 'Configuration of the webide terminal.'

          attributes :terminal

          entry :json_schemas, Entry::Schemas,
            description: 'Configuration of JSON schemas'

          attributes :json_schemas

          entry :yaml_schemas, Entry::Schemas,
            description: 'Configuration of YAML schemas'

          attributes :yaml_schemas
        end
      end
    end
  end
end
