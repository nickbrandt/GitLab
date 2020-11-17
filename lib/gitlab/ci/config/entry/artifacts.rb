# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of job artifacts (archives and reports).
        #
        class Artifacts < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Configurable
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Attributable
          include ::Gitlab::Ci::Config::Entry::Archivable

          ALLOWED_KEYS = (ARCHIVE_KEYS + %i[reports archives]).freeze

          attributes ALLOWED_KEYS

          entry :reports, Entry::Reports, description: 'Report-type artifacts.'
          entry :archives, ::Gitlab::Config::Entry::ComposableArray,
            description: 'Archive-type artifact',
            metadata: { composable_class: ::Gitlab::Ci::Config::Entry::Archive }

          validations do
            validates :config, allowed_keys: ALLOWED_KEYS

            with_options allow_nil: true do
              validates :reports, type: Hash
              validates :archives, type: Array
            end
          end

          def value
            @config[:reports] = reports_value if @config.key?(:reports)
            @config
          end
        end
      end
    end
  end
end
