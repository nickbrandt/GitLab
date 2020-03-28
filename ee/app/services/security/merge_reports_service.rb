# frozen_string_literal: true

module Security
  class MergeReportsService
    IdentifierKey = Struct.new(:location_sha, :identifier_type, :identifier_value) do
      def ==(other)
        location_sha == other.location_sha &&
          identifier_type == other.identifier_type &&
          identifier_value == other.identifier_value
      end

      def hash
        location_sha.hash ^ identifier_type.hash ^ identifier_value.hash
      end

      alias_method :eql?, :==
    end

    def initialize(*source_reports)
      @source_reports = source_reports
      @target_report = ::Gitlab::Ci::Reports::Security::Report.new(
        @source_reports.first.type,
        @source_reports.first.commit_sha,
        @source_reports.first.created_at
      )
      @occurrences = []
    end

    def execute
      @source_reports.each do |source|
        copy_scanners_to_target(source)
        copy_identifiers_to_target(source)
        copy_occurrences_to_buffer(source)
      end

      copy_occurrences_to_target

      @target_report
    end

    private

    def copy_scanners_to_target(source_report)
      # no need for de-duping: it's done by Report internally
      source_report.scanners.values.each { |scanner| @target_report.add_scanner(scanner) }
    end

    def copy_identifiers_to_target(source_report)
      # no need for de-duping: it's done by Report internally
      source_report.identifiers.values.each { |identifier| @target_report.add_identifier(identifier) }
    end

    def copy_occurrences_to_buffer(source)
      @occurrences.concat(source.occurrences)
    end

    # this method mutates the passed seen_identifiers set
    def check_or_mark_seen_identifier!(identifier, location_fingerprint, seen_identifiers)
      key = IdentifierKey.new(location_fingerprint, identifier.external_type, identifier.external_id)

      if seen_identifiers.include?(key)
        true
      else
        seen_identifiers.add(key)
        false
      end
    end

    def deduplicate_occurrences!
      seen_identifiers = Set.new
      deduplicated = []

      @occurrences.each do |occurrence|
        seen = false

        # We are looping through all identifiers in order to find the same vulnerabilities reported for the same location
        # but from different source reports and keeping only first of them
        occurrence.identifiers.each do |identifier|
          # TODO: remove .downcase here after the DAST parser is harmonized to the common library identifiers' keys format
          # See https://gitlab.com/gitlab-org/gitlab/issues/11976#note_191257912
          next if %w[cwe wasc].include?(identifier.external_type.downcase) # ignored because these describe a class of vulnerabilities

          seen = check_or_mark_seen_identifier!(identifier, occurrence.location.fingerprint, seen_identifiers)

          break if seen
        end

        deduplicated << occurrence unless seen
      end

      @occurrences = deduplicated
    end

    def sort_occurrences!
      @occurrences.sort! do |a, b|
        a_severity, b_severity = a.severity, b.severity

        if a_severity == b_severity
          a.compare_key <=> b.compare_key
        else
          Vulnerabilities::Occurrence::SEVERITY_LEVELS[b_severity] <=>
            Vulnerabilities::Occurrence::SEVERITY_LEVELS[a_severity]
        end
      end
    end

    def copy_occurrences_to_target
      deduplicate_occurrences!
      sort_occurrences!

      @occurrences.each { |occurrence| @target_report.add_occurrence(occurrence) }
    end
  end
end
