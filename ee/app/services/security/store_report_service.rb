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

      vulnerability_ids = create_all_vulnerabilities!
      mark_as_resolved_except(vulnerability_ids)

      start_auto_fix

      success
    end

    private

    def executed?
      pipeline.vulnerability_findings.report_type(@report.type).any?
    end

    def create_all_vulnerabilities!
      # Look for existing Findings using UUID
      finding_uuids = @report.findings.map(&:uuid)
      vulnerability_findings_by_uuid = project.vulnerability_findings
        .where(uuid: finding_uuids) # rubocop: disable CodeReuse/ActiveRecord
        .to_h { |vf| [vf.uuid, vf] }
      remediations_by_checksum = find_existing_remediations_for(@report.findings)

      @report.findings.map do |finding|
        create_vulnerability_finding(
          vulnerability_findings_by_uuid,
          remediations_by_checksum,
          finding
        )&.id
      end.compact.uniq
    end

    def find_existing_remediations_for(findings)
      checksums = findings.flat_map { |f| f.remediations.map(&:checksum) }

      project.vulnerability_remediations.by_checksum(checksums).to_h { |r| [r.checksum, r] }
    end

    def mark_as_resolved_except(vulnerability_ids)
      project.vulnerabilities
             .with_report_types(report.type)
             .id_not_in(vulnerability_ids)
             .update_all(resolved_on_default_branch: true)
    end

    def create_vulnerability_finding(vulnerability_findings_by_uuid, remediations_by_checksum, finding)
      unless finding.valid?
        put_warning_for(finding)
        return
      end

      vulnerability_params = finding.to_hash.except(:compare_key, :identifiers, :location, :scanner, :scan, :links)
      entity_params = Gitlab::Json.parse(vulnerability_params&.dig(:raw_metadata)).slice('description', 'message', 'solution', 'cve', 'location')
      # Vulnerabilities::Finding (`vulnerability_occurrences`)
      vulnerability_finding = vulnerability_findings_by_uuid[finding.uuid] ||
        create_new_vulnerability_finding(finding, vulnerability_params.merge(entity_params))

      update_vulnerability_scanner(finding)

      update_vulnerability_finding(vulnerability_finding, vulnerability_params)

      reset_remediations_for(finding, vulnerability_finding, remediations_by_checksum)

      update_finding_fingerprints(finding, vulnerability_finding)

      # The maximum number of identifiers is not used in validation
      # we just want to ignore the rest if a finding has more than that.
      finding.identifiers.take(Vulnerabilities::Finding::MAX_NUMBER_OF_IDENTIFIERS).map do |identifier| # rubocop: disable CodeReuse/ActiveRecord
        create_or_update_vulnerability_identifier_object(vulnerability_finding, identifier)
      end

      create_or_update_vulnerability_links(finding, vulnerability_finding)

      create_vulnerability_pipeline_object(vulnerability_finding, pipeline)

      create_vulnerability(vulnerability_finding, pipeline)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def create_new_vulnerability_finding(finding, create_params)
      find_params = {
        scanner: scanners_objects[finding.scanner.key],
        primary_identifier: identifiers_objects[finding.primary_identifier.key],
        location_fingerprint: finding.location.fingerprint
      }

      begin
        # If there's no Finding then we're dealing with one of two cases:
        # 1. The Finding is a new one
        # 2. The Finding is already saved but has UUIDv4
        project.vulnerability_findings
          .create_with(create_params)
          .find_or_initialize_by(find_params).tap do |f|
          f.uuid = finding.uuid
          f.save!
        end
      rescue ActiveRecord::RecordNotUnique => e
        # This might happen if we're processing another report in parallel and it finds the same Finding
        # faster. In that case we need to perform the lookup again

        by_uuid = project.vulnerability_findings.reset.find_by(uuid: finding.uuid)
        return by_uuid if by_uuid

        by_find_params = project.vulnerability_findings.reset.find_by(find_params)
        return by_find_params if by_find_params

        Gitlab::ErrorTracking.track_and_raise_exception(e, find_params: find_params, uuid: finding.uuid)
      rescue ActiveRecord::ActiveRecordError => e
        Gitlab::ErrorTracking.track_and_raise_exception(e, create_params: create_params&.dig(:raw_metadata))
      end
    end

    def update_vulnerability_scanner(finding)
      scanner = scanners_objects[finding.scanner.key]
      scanner.update!(finding.scanner.to_hash)
    end

    def update_vulnerability_finding(vulnerability_finding, update_params)
      vulnerability_finding.update!(update_params)
    end

    def create_or_update_vulnerability_identifier_object(vulnerability_finding, identifier)
      identifier_object = identifiers_objects[identifier.key]
      vulnerability_finding.finding_identifiers.find_or_create_by!(identifier: identifier_object)
      identifier_object.update!(identifier.to_hash)
    rescue ActiveRecord::RecordNotUnique
    end

    def create_or_update_vulnerability_links(finding, vulnerability_finding)
      return if finding.links.blank?

      finding.links.each do |link|
        vulnerability_finding.finding_links.safe_find_or_create_by!(link.to_hash)
      end
    rescue ActiveRecord::RecordNotUnique
    end

    def reset_remediations_for(finding, vulnerability_finding, remediations_by_checksum)
      existing_remediations = remediations_by_checksum.values
      existing_remediation_checksums = remediations_by_checksum.keys
      new_remediations = build_new_remediations_for(finding.remediations, existing_remediation_checksums)

      vulnerability_finding.remediations = existing_remediations + new_remediations
    end

    def build_new_remediations_for(current_remediations, existing_remediation_checksums)
      missing_remediations = current_remediations.select do |remediation|
        !remediation.checksum.in?(existing_remediation_checksums)
      end
      missing_remediations.map { |remediation| build_vulnerability_remediation(remediation) }
    end

    def build_vulnerability_remediation(remediation)
      @project.vulnerability_remediations.new(summary: remediation.summary, file: remediation.diff_file, checksum: remediation.checksum)
    end

    def create_vulnerability_pipeline_object(vulnerability_finding, pipeline)
      vulnerability_finding.finding_pipelines.find_or_create_by!(pipeline: pipeline)
    rescue ActiveRecord::RecordNotUnique
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def update_finding_fingerprints(finding, vulnerability_finding)
      to_update = {}
      to_create = []

      poro_fingerprints = finding.fingerprints.index_by(&:algorithm_type)

      vulnerability_finding.fingerprints.each do |fingerprint|
        # NOTE: index_by takes the last entry if there are duplicates of the same algorithm, which should never occur.
        poro_fingerprint = poro_fingerprints[fingerprint.algorithm_type]

        # We're no longer generating these types of fingerprints. Since
        # we're updating the persisted vulnerability, no need to do anything
        # with these fingerprints now. We will track growth with
        # https://gitlab.com/gitlab-org/gitlab/-/issues/322186
        next if poro_fingerprint.nil?

        poro_fingerprints.delete(fingerprint.algorithm_type)
        to_update[fingerprint.id] = poro_fingerprint.to_h
      end

      # any remaining poro fingerprints left are new
      poro_fingerprints.values.each do |poro_fingerprint|
        attributes = poro_fingerprint.to_h.merge(finding_id: vulnerability_finding.id)
        to_create << ::Vulnerabilities::FindingFingerprint.new(attributes: attributes, created_at: Time.zone.now, updated_at: Time.zone.now)
      end

      ::Vulnerabilities::FindingFingerprint.transaction do
        if to_update.count > 0
          ::Vulnerabilities::FindingFingerprint.update(to_update.keys, to_update.values)
        end

        if to_create.count > 0
          ::Vulnerabilities::FindingFingerprint.bulk_insert!(to_create)
        end
      end
    end

    def create_vulnerability(vulnerability_finding, pipeline)
      if vulnerability_finding.vulnerability_id
        Vulnerabilities::UpdateService.new(vulnerability_finding.project, pipeline.user, finding: vulnerability_finding, resolved_on_default_branch: false).execute
      else
        Vulnerabilities::CreateService.new(vulnerability_finding.project, pipeline.user, finding_id: vulnerability_finding.id).execute
      end
    end

    def scanners_objects
      strong_memoize(:scanners_objects) do
        @report.scanners.map do |key, scanner|
          [key, existing_scanner_objects[key] || project.vulnerability_scanners.build(scanner&.to_hash)]
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

    def put_warning_for(finding)
      Gitlab::AppLogger.warn(message: "Invalid vulnerability finding record found", finding: finding.to_hash)
    end

    def start_auto_fix
      return unless auto_fix_enabled?

      ::Security::AutoFixWorker.perform_async(pipeline.id)
    end

    def auto_fix_enabled?
      return false unless project.security_setting&.auto_fix_enabled?

      project.security_setting.auto_fix_enabled_types.include?(report.type.to_sym)
    end
  end

  StoreReportService.prepend(Measurable)
end
