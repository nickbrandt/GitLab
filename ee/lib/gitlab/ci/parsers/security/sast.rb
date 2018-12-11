# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class Sast < Common
          private

          def metadata_version(vulnerability)
            '1.2'
          end

          def generate_location_fingerprint(location)
            Digest::SHA1.hexdigest("#{location['file']}:#{location['start_line']}:#{location['end_line']}")
          end
        end
      end
    end
  end
end
