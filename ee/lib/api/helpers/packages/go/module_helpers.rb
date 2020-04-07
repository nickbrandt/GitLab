# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Go
        module ModuleHelpers
          # basic semver regex
          SEMVER_REGEX = /v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([-.a-z0-9]+))?(?:\+([-.a-z0-9]+))?/i.freeze

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

            ::Packages::SemVer.match?(tag.name, prefixed: true)
          end

          def pseudo_version?(str)
            ::Packages::SemVer.match?(str, prefixed: true) && PSEUDO_VERSION_REGEX.match?(str)
          end

          def parse_semver(str)
            ::Packages::SemVer.parse(str, prefixed: true)
          end
        end
      end
    end
  end
end
