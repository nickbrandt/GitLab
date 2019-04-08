# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        module Locations
          class Base
            include ::Gitlab::Utils::StrongMemoize

            def ==(other)
              other.fingerprint == fingerprint
            end

            def fingerprint
              strong_memoize(:fingerprint) do
                Digest::SHA1.hexdigest(fingerprint_data)
              end
            end

            private

            def fingerprint_data
              raise NotImplemented
            end
          end
        end
      end
    end
  end
end
