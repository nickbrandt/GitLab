# frozen_string_literal: true

module Vulnerabilities
  class Occurrence < ApplicationRecord
    include ShaAttribute
    include ::Gitlab::Utils::StrongMemoize
    include Presentable

    self.table_name = "vulnerability_occurrences"

    OCCURRENCES_PER_PAGE = 20

    paginates_per OCCURRENCES_PER_PAGE

    sha_attribute :project_fingerprint
    sha_attribute :location_fingerprint

    belongs_to :project
    belongs_to :scanner, class_name: 'Vulnerabilities::Scanner'
    belongs_to :primary_identifier, class_name: 'Vulnerabilities::Identifier', inverse_of: :primary_occurrences
    belongs_to :vulnerability, inverse_of: :findings

    has_many :occurrence_identifiers, class_name: 'Vulnerabilities::OccurrenceIdentifier'
    has_many :identifiers, through: :occurrence_identifiers, class_name: 'Vulnerabilities::Identifier'
    has_many :occurrence_pipelines, class_name: 'Vulnerabilities::OccurrencePipeline'
    has_many :pipelines, through: :occurrence_pipelines, class_name: 'Ci::Pipeline'

    attr_writer :sha

    CONFIDENCE_LEVELS = {
      undefined: 0,
      ignore: 1,
      unknown: 2,
      experimental: 3,
      low: 4,
      medium: 5,
      high: 6,
      confirmed: 7
    }.with_indifferent_access.freeze

    SEVERITY_LEVELS = {
      undefined: 0,
      info: 1,
      unknown: 2,
      # experimental: 3, formerly used by confidence, no longer applicable
      low: 4,
      medium: 5,
      high: 6,
      critical: 7
    }.with_indifferent_access.freeze

    REPORT_TYPES = {
      sast: 0,
      dependency_scanning: 1,
      container_scanning: 2,
      dast: 3
    }.with_indifferent_access.freeze

    enum confidence: CONFIDENCE_LEVELS, _prefix: :confidence
    enum report_type: REPORT_TYPES
    enum severity: SEVERITY_LEVELS, _prefix: :severity

    validates :scanner, presence: true
    validates :project, presence: true
    validates :uuid, presence: true

    validates :primary_identifier, presence: true
    validates :project_fingerprint, presence: true
    validates :location_fingerprint, presence: true
    # Uniqueness validation doesn't work with binary columns, so save this useless query. It is enforce by DB constraint anyway.
    # TODO: find out why it fails
    # validates :location_fingerprint, presence: true, uniqueness: { scope: [:primary_identifier_id, :scanner_id, :ref, :pipeline_id, :project_id] }
    validates :name, presence: true
    validates :report_type, presence: true
    validates :severity, presence: true
    validates :confidence, presence: true

    validates :metadata_version, presence: true
    validates :raw_metadata, presence: true

    scope :report_type, -> (type) { where(report_type: report_types[type]) }
    scope :ordered, -> { order(severity: :desc, confidence: :desc, id: :asc) }

    scope :by_report_types, -> (values) { where(report_type: values) }
    scope :by_projects, -> (values) { where(project_id: values) }
    scope :by_severities, -> (values) { where(severity: values) }
    scope :by_confidences, -> (values) { where(confidence: values) }

    scope :all_preloaded, -> do
      preload(:scanner, :identifiers, project: [:namespace, :project_feature])
    end

    scope :scoped_project, -> { where('vulnerability_occurrences.project_id = projects.id') }

    def self.for_pipelines_with_sha(pipelines)
      joins(:pipelines)
        .where(ci_pipelines: { id: pipelines })
        .select("vulnerability_occurrences.*, ci_pipelines.sha")
    end

    def self.for_pipelines(pipelines)
      joins(:occurrence_pipelines)
        .where(vulnerability_occurrence_pipelines: { pipeline_id: pipelines })
    end

    def self.count_by_day_and_severity(period)
      joins(:occurrence_pipelines)
        .select('CAST(vulnerability_occurrence_pipelines.created_at AS DATE) AS day', :severity, 'COUNT(distinct vulnerability_occurrences.id) as count')
        .where(['vulnerability_occurrence_pipelines.created_at >= ?', Time.zone.now.beginning_of_day - period])
        .group(:day, :severity)
        .order('day')
    end

    def self.counted_by_severity
      group(:severity).count.each_with_object({}) do |(severity, count), accum|
        accum[SEVERITY_LEVELS[severity]] = count
      end
    end

    def self.with_vulnerabilities_for_state(project:, report_type:, project_fingerprints:)
      Vulnerabilities::Occurrence
        .joins(:vulnerability)
        .where(
          project: project,
          report_type: report_type,
          project_fingerprint: project_fingerprints
        )
        .select('vulnerability_occurrences.report_type, vulnerability_id, project_fingerprint, raw_metadata, '\
                'vulnerabilities.id, vulnerabilities.state') # fetching only required attributes
    end

    # sha can be sourced from a joined pipeline or set from the report
    def sha
      self[:sha] || @sha
    end

    def state
      return 'dismissed' if dismissal_feedback.present?

      if vulnerability.nil?
        'opened'
      elsif vulnerability.resolved?
        'resolved'
      elsif vulnerability.closed? # fail-safe check for cases when dismissal feedback was lost or was not created
        'dismissed'
      else
        'confirmed'
      end
    end

    def self.undismissed
      where(
        "NOT EXISTS (?)",
        Feedback.select(1)
        .where("#{table_name}.report_type = vulnerability_feedback.category")
        .where("#{table_name}.project_id = vulnerability_feedback.project_id")
        .where("ENCODE(#{table_name}.project_fingerprint, 'HEX') = vulnerability_feedback.project_fingerprint") # rubocop:disable GitlabSecurity/SqlInjection
        .for_dismissal
      )
    end

    def self.batch_count_by_project_and_severity(project_id, severity)
      BatchLoader.for(project_id: project_id, severity: severity).batch(default_value: 0) do |items, loader|
        project_ids = items.map { |i| i[:project_id] }.uniq
        severities = items.map { |i| i[:severity] }.uniq

        counts = undismissed
          .by_severities(severities)
          .by_projects(project_ids)
          .group(:project_id, :severity)
          .count

        counts.each do |(found_project_id, found_severity), count|
          loader_key = { project_id: found_project_id, severity: found_severity }
          loader.call(loader_key, count)
        end
      end
    end

    def feedback(feedback_type:)
      params = {
        project_id: project_id,
        category: report_type,
        project_fingerprint: project_fingerprint,
        feedback_type: feedback_type
      }

      BatchLoader.for(params).batch do |items, loader|
        project_ids = items.map { |i| i[:project_id] }
        categories = items.map { |i| i[:category] }
        fingerprints = items.map { |i| i[:project_fingerprint] }

        Vulnerabilities::Feedback.all_preloaded.where(
          project_id: project_ids.uniq,
          category: categories.uniq,
          project_fingerprint: fingerprints.uniq
        ).each do |feedback|
          loaded_params = {
            project_id: feedback.project_id,
            category: feedback.category,
            project_fingerprint: feedback.project_fingerprint,
            feedback_type: feedback.feedback_type
          }
          loader.call(loaded_params, feedback)
        end
      end
    end

    def dismissal_feedback
      feedback(feedback_type: 'dismissal')
    end

    def issue_feedback
      feedback(feedback_type: 'issue')
    end

    def merge_request_feedback
      feedback(feedback_type: 'merge_request')
    end

    def metadata
      strong_memoize(:metadata) do
        JSON.parse(raw_metadata)
      rescue JSON::ParserError
        {}
      end
    end

    def description
      metadata.dig('description')
    end

    def solution
      metadata.dig('solution')
    end

    def location
      metadata.fetch('location', {})
    end

    def links
      metadata.fetch('links', [])
    end

    def remediations
      metadata.dig('remediations')
    end

    alias_method :==, :eql? # eql? is necessary in some cases like array intersection

    def eql?(other)
      other.report_type == report_type &&
        other.location_fingerprint == location_fingerprint &&
        other.first_fingerprint == first_fingerprint
    end

    # Array.difference (-) method uses hash and eql? methods to do comparison
    def hash
      report_type.hash ^ location_fingerprint.hash ^ first_fingerprint.hash
    end

    def severity_value
      self.class.severities[self.severity]
    end

    def confidence_value
      self.class.confidences[self.confidence]
    end

    protected

    def first_fingerprint
      identifiers.first&.fingerprint
    end
  end
end
