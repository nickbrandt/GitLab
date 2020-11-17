# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of a job archive.
        #
        class Archive < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable
          include ::Gitlab::Config::Entry::Attributable
          include ::Gitlab::Ci::Config::Entry::Archivable

          attributes ARCHIVE_KEYS

          validations do
            validates :config, allowed_keys: ARCHIVE_KEYS
          end
        end
      end
    end
  end
end
