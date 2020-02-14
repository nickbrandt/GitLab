# frozen_string_literal: true

module Security
  # Service for storing a given security report into the database.
  #
  class StoreReportService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    attr_reader :pipeline, :report, :project

    def initialize(pipeline, report)
      @pipeline = pipeline
      @report = report
      @project = @pipeline.project
    end

    def execute
      # Ensure we're not trying to insert data twice for this report
      return error("#{@report.type} report already stored for this pipeline, skipping...") if executed?

      create_all_vulnerabilities!

      success
    end

    private

    def executed?
      pipeline.vulnerability_findings.report_type(@report.type).any?
    end

    def create_all_vulnerabilities!
      @report.occurrences.each do |occurrence|
        create_vulnerability_finding(occurrence)
      end
    end

    def create_vulnerability_finding(occurrence)
      vulnerability_finding = create_or_find_vulnerability_finding(occurrence)

      occurrence.identifiers.map do |identifier|
        create_vulnerability_identifier_object(vulnerability_finding, identifier)
      end

      create_vulnerability_pipeline_object(vulnerability_finding, pipeline)

      create_vulnerability(vulnerability_finding, pipeline)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def create_or_find_vulnerability_finding(occurrence)
      find_params = {
        scanner: scanners_objects[occurrence.scanner.key],
        primary_identifier: identifiers_objects[occurrence.primary_identifier.key],
        location_fingerprint: occurrence.location.fingerprint
      }

      create_params = occurrence.to_hash
        .except(:compare_key, :identifiers, :location, :scanner)

      begin
        project
          .vulnerability_findings
          .create_with(create_params)
          .find_or_create_by!(find_params)
      rescue ActiveRecord::RecordNotUnique
        project.vulnerability_findings.find_by!(find_params)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def create_vulnerability_identifier_object(vulnerability_finding, identifier)
      vulnerability_finding.occurrence_identifiers.find_or_create_by!( # rubocop: disable CodeReuse/ActiveRecord
        identifier: identifiers_objects[identifier.key])
    rescue ActiveRecord::RecordNotUnique
    end

    def create_vulnerability_pipeline_object(vulnerability_finding, pipeline)
      vulnerability_finding.occurrence_pipelines.find_or_create_by!(pipeline: pipeline) # rubocop: disable CodeReuse/ActiveRecord
    rescue ActiveRecord::RecordNotUnique
    end

    def create_vulnerability(vulnerability_finding, pipeline)
      return if vulnerability_finding.vulnerability_id

      Vulnerabilities::CreateService.new(vulnerability_finding.project, pipeline.user, finding_id: vulnerability_finding.id).execute
    end

    def scanners_objects
      strong_memoize(:scanners_objects) do
        @report.scanners.map do |key, scanner|
          [key, existing_scanner_objects[key] || project.vulnerability_scanners.build(scanner.to_hash)]
        end.to_h
      end
    end

    def all_scanners_external_ids
      @report.scanners.values.map(&:external_id)
    end

    def existing_scanner_objects
      strong_memoize(:existing_scanner_objects) do
        project.vulnerability_scanners.with_external_id(all_scanners_external_ids).map do |scanner|
          [scanner.external_id, scanner]
        end.to_h
      end
    end

    def identifiers_objects
      strong_memoize(:identifiers_objects) do
        @report.identifiers.map do |key, identifier|
          [key, existing_identifiers_objects[key] || project.vulnerability_identifiers.build(identifier.to_hash)]
        end.to_h
      end
    end

    def all_identifiers_fingerprints
      @report.identifiers.values.map(&:fingerprint)
    end

    def existing_identifiers_objects
      strong_memoize(:existing_identifiers_objects) do
        project.vulnerability_identifiers.with_fingerprint(all_identifiers_fingerprints).map do |identifier|
          [identifier.fingerprint, identifier]
        end.to_h
      end
    end
  end
end
