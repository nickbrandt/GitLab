# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # For extending entries to have the configuration of a job artifact archive.
        #
        module Archivable
          extend ActiveSupport::Concern

          ARCHIVE_KEYS = %i[name untracked paths when expire_in expose_as exclude].freeze
          EXPOSE_AS_REGEX = /\A\w[-\w ]*\z/.freeze
          EXPOSE_AS_ERROR_MESSAGE = "can contain only letters, digits, '-', '_' and spaces"

          included do
            validations do
              validates :config, type: Hash
              validates :paths, presence: true, if: :expose_as_present?
              with_options allow_nil: true do
                validates :name, type: String
                validates :untracked, boolean: true
                validates :paths, array_of_strings: true
                validates :paths, array_of_strings: {
                  with: /\A[^*]*\z/,
                  message: "can't contain '*' when used with 'expose_as'"
                }, if: :expose_as_present?
                validates :expose_as, type: String, length: { maximum: 100 }, if: :expose_as_present?
                validates :expose_as, format: { with: EXPOSE_AS_REGEX, message: EXPOSE_AS_ERROR_MESSAGE }, if: :expose_as_present?
                validates :exclude, array_of_strings: true, if: :exclude_enabled?
                validates :exclude, absence: { message: 'feature is disabled' }, unless: :exclude_enabled?
                validates :when,
                          inclusion: {
                            in: %w[on_success on_failure always],
                            message: 'should be on_success, on_failure or always'
                          }
                validates :expire_in, duration: { parser: ::Gitlab::Ci::Build::Artifacts::ExpireInParser }
              end
            end
          end

          # rubocop:disable Gitlab/ModuleWithInstanceVariables
          def expose_as_present?
            # This duplicates the `validates :config, type: Hash` above,
            # but Validatable currently doesn't halt the validation
            # chain if it encounters a validation error.
            return false unless @config.is_a?(Hash)

            !@config[:expose_as].nil?
          end
          # rubocop:enable Gitlab/ModuleWithInstanceVariables

          def exclude_enabled?
            ::Gitlab::Ci::Features.artifacts_exclude_enabled?
          end
        end
      end
    end
  end
end
