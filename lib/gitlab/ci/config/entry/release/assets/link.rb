# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of release:assets:links.
        #
        class Release
          class Assets
            class Link < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Validatable
              include ::Gitlab::Config::Entry::Attributable

              ALLOWED_KEYS = %i[name url file filepath].freeze

              attributes ALLOWED_KEYS

              validations do
                validates :config, allowed_keys: ALLOWED_KEYS

                validates :name, type: String, presence: true
                validates :url, addressable_url: true, presence: true
                validates :file, type: String, allow_blank: true
                validates :filepath, format: { with: ::Releases::Link::FILEPATH_REGEX }, length: { maximum: 128 }, allow_blank: true
              end
            end
          end
        end
      end
    end
  end
end
