# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Report
          attr_reader :type
          attr_reader :commit_sha
          attr_reader :occurrences
          attr_reader :scanners
          attr_reader :identifiers

          attr_accessor :error

          def initialize(type, commit_sha)
            @type = type
            @commit_sha = commit_sha
            @occurrences = []
            @scanners = {}
            @identifiers = {}
          end

          def errored?
            error.present?
          end

          def add_scanner(scanner)
            scanners[scanner.key] ||= scanner
          end

          def add_identifier(identifier)
            identifiers[identifier.key] ||= identifier
          end

          def add_occurrence(occurrence)
            occurrences << occurrence
          end
        end
      end
    end
  end
end
