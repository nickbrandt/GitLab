# frozen_string_literal: true

module EE
  # CI::JobArtifact EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Ci::JobArtifact` model
  module Ci::JobArtifact
    extend ActiveSupport::Concern

    prepended do
      after_destroy :log_geo_deleted_event

      SECURITY_REPORT_FILE_TYPES = %w[sast dependency_scanning container_scanning dast].freeze
      LICENSE_MANAGEMENT_REPORT_FILE_TYPES = %w[license_management].freeze
      DEPENDENCY_LIST_REPORT_FILE_TYPES = %w[dependency_scanning].freeze
      METRICS_REPORT_FILE_TYPES = %w[metrics].freeze
      CONTAINER_SCANNING_REPORT_TYPES = %w[container_scanning].freeze
      SAST_REPORT_TYPES = %w[sast].freeze
      DAST_REPORT_TYPES = %w[dast].freeze

      scope :not_expired, -> { where('expire_at IS NULL OR expire_at > ?', Time.current) }
      scope :project_id_in, ->(ids) { joins(:project).merge(::Project.id_in(ids)) }
      scope :with_files_stored_remotely, -> { where(file_store: ::JobArtifactUploader::Store::REMOTE) }

      scope :security_reports, -> do
        with_file_types(SECURITY_REPORT_FILE_TYPES)
      end

      scope :license_management_reports, -> do
        with_file_types(LICENSE_MANAGEMENT_REPORT_FILE_TYPES)
      end

      scope :dependency_list_reports, -> do
        with_file_types(DEPENDENCY_LIST_REPORT_FILE_TYPES)
      end

      scope :container_scanning_reports, -> do
        with_file_types(CONTAINER_SCANNING_REPORT_TYPES)
      end

      scope :sast_reports, -> do
        with_file_types(SAST_REPORT_TYPES)
      end

      scope :dast_reports, -> do
        with_file_types(DAST_REPORT_TYPES)
      end

      scope :metrics_reports, -> do
        with_file_types(METRICS_REPORT_FILE_TYPES)
      end
    end

    def log_geo_deleted_event
      ::Geo::JobArtifactDeletedEventStore.new(self).create!
    end
  end
end
