# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class DependencyScanning < Common
          private

          def metadata_version(vulnerability)
            '1.3'
          end

          def generate_location_fingerprint(location)
            Digest::SHA1.hexdigest("#{location['file']}:#{location['dependency']['package']['name']}")
          end
        end
      end
    end
  end
end
