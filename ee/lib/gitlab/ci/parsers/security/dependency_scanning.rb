# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class DependencyScanning < Common
          include Security::Concerns::DeprecatedSyntax

          DEPRECATED_REPORT_VERSION = "1.3".freeze

          private

          def generate_location_fingerprint(location)
            Digest::SHA1.hexdigest("#{location['file']}:#{location.dig('dependency', 'package', 'name')}")
          end
        end
      end
    end
  end
end
