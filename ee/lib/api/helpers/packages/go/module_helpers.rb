# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Go
        module ModuleHelpers
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

          def pseudo_version?(version)
            return false unless version

            if version.is_a? String
              version = parse_semver version
              return false unless version
            end

            pre = version.prerelease

            # valid pseudo-versions are
            #   vX.0.0-yyyymmddhhmmss-sha1337beef0, when no earlier tagged commit exists for X
            #   vX.Y.Z-pre.0.yyyymmddhhmmss-sha1337beef0, when most recent prior tag is vX.Y.Z-pre
            #   vX.Y.(Z+1)-0.yyyymmddhhmmss-sha1337beef0, when most recent prior tag is vX.Y.Z

            if version.minor != 0 || version.patch != 0
              m = /\A(.*\.)?0\./.freeze.match pre
              return false unless m

              pre = pre[m[0].length..]
            end

            /\A\d{14}-[A-Za-z0-9]+\z/.freeze.match? pre
          end

          def parse_semver(str)
            ::Packages::SemVer.parse(str, prefixed: true)
          end
        end
      end
    end
  end
end
