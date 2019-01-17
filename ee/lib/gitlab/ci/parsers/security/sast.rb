# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class Sast < Common
          include Security::Concerns::DeprecatedSyntax

          DEPRECATED_REPORT_VERSION = "1.2".freeze

          private

          def generate_location_fingerprint(location)
            Digest::SHA1.hexdigest("#{location['file']}:#{location['start_line']}:#{location['end_line']}")
          end
        end
      end
    end
  end
end
