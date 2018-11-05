# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Report
          attr_reader :type
          attr_reader :occurrences
          attr_reader :scanners
          attr_reader :identifiers
          attr_accessor :error

          def initialize(type)
            @type = type
            @occurrences = []
            @scanners = {}
            @identifiers = {}
          end

          def errored?
            error.present?
          end

          def add_scanner(params)
            scanner_key(params).tap do |key|
              scanners[key] ||= params
            end
          end

          def add_identifier(params)
            identifier_key(params).tap do |key|
              identifiers[key] ||= params
            end
          end

          def add_occurrence(params)
            params.tap do |occurrence|
              occurrences << occurrence
            end
          end

          private

          def scanner_key(params)
            params.fetch(:external_id)
          end

          def identifier_key(params)
            params.fetch(:fingerprint)
          end
        end
      end
    end
  end
end
