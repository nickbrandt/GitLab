# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Go
        module ModuleHelpers
          # basic semver regex
          SEMVER_REGEX = /v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([-.a-z0-9]+))?(?:\+([-.a-z0-9]+))?/i.freeze

          # basic semver, but bounded (^expr$)
          SEMVER_TAG_REGEX = /^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([-.a-z0-9]+))?(?:\+([-.a-z0-9]+))?$/i.freeze

          # semver, but the prerelease component follows a specific format
          PSEUDO_VERSION_REGEX = /^v\d+\.(0\.0-|\d+\.\d+-([^+]*\.)?0\.)\d{14}-[A-Za-z0-9]+(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$/i.freeze

          def case_encode(str)
            str.gsub(/A-Z/) { |s| "!#{s.downcase}"}
          end

          def case_decode(str)
            str.gsub(/![[:alpha:]]/) { |s| s[1..].upcase }
          end

          def semver?(tag)
            return false if tag.dereferenced_target.nil?

            SEMVER_TAG_REGEX.match?(tag.name)
          end

          def pseudo_version?(str)
            SEMVER_TAG_REGEX.match?(str) && PSEUDO_VERSION_REGEX.match?(str)
          end

          def parse_semver(str)
            m = SEMVER_TAG_REGEX.match(str)
            return unless m

            OpenStruct.new(
              major: m[1].to_i,
              minor: m[2].to_i,
              patch: m[3].to_i,
              prerelease: m[4],
              build: m[5])
          end
        end
      end
    end
  end
end
