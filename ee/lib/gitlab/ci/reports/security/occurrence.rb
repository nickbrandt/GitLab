# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Occurrence
          attr_reader :compare_key
          attr_reader :confidence
          attr_reader :identifiers
          attr_reader :location_fingerprint
          attr_reader :metadata_version
          attr_reader :name
          attr_reader :project_fingerprint
          attr_reader :raw_metadata
          attr_reader :report_type
          attr_reader :scanner
          attr_reader :severity
          attr_reader :uuid

          def initialize(compare_key:, identifiers:, location_fingerprint:, metadata_version:, name:, raw_metadata:, report_type:, scanner:, uuid:, confidence: nil, severity: nil) # rubocop:disable Metrics/ParameterLists
            @compare_key = compare_key
            @confidence = confidence
            @identifiers = identifiers
            @location_fingerprint = location_fingerprint
            @metadata_version = metadata_version
            @name = name
            @raw_metadata = raw_metadata
            @report_type = report_type
            @scanner = scanner
            @severity = severity
            @uuid = uuid

            @project_fingerprint = generate_project_fingerprint
          end

          def to_hash
            %i[
              compare_key
              confidence
              identifiers
              location_fingerprint
              metadata_version
              name
              project_fingerprint
              raw_metadata
              report_type
              scanner
              severity
              uuid
            ].each_with_object({}) do |key, hash|
              hash[key] = public_send(key) # rubocop:disable GitlabSecurity/PublicSend
            end
          end

          def primary_identifier
            identifiers.first
          end

          def ==(other)
            other.report_type == report_type &&
              other.location_fingerprint == location_fingerprint &&
              other.primary_identifier == primary_identifier
          end

          private

          def generate_project_fingerprint
            Digest::SHA1.hexdigest(compare_key)
          end
        end
      end
    end
  end
end
