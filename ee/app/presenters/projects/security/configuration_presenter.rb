# frozen_string_literal: true

module Projects
  module Security
    class ConfigurationPresenter < Gitlab::View::Presenter::Delegated
      include Gitlab::Utils::StrongMemoize

      presents :project

      SCAN_DESCRIPTIONS = {
        container_scanning: _('Check your Docker images for known vulnerabilities'),
        dast: _('Analyze a review version of your web application.'),
        dependency_scanning: _('Analyze your dependencies for known vulnerabilities'),
        license_management: _('Search your project dependencies for their licenses and apply policies'),
        sast: _('Analyze your source code for known vulnerabilities')
      }.freeze

      SCAN_DOCS = {
        container_scanning: 'user/application_security/container_scanning/index',
        dast: 'user/application_security/dast/index',
        dependency_scanning: 'user/application_security/dependency_scanning/index',
        license_management: 'user/application_security/license_compliance/index',
        sast: 'user/application_security/sast/index'
      }.freeze

      SCAN_NAMES = {
        container_scanning: _('Container Scanning'),
        dast: _('Dynamic Application Security Testing (DAST)'),
        dependency_scanning: _('Dependency Scanning'),
        license_management: _('License Compliance'),
        sast: _('Static Application Security Testing (SAST)')
      }.freeze

      def to_h
        {
          auto_devops_enabled: auto_devops_source?,
          auto_devops_help_page_path: help_page_path('topics/autodevops/index'),
          features: features.to_json,
          help_page_path: help_page_path('user/application_security/index'),
          latest_pipeline_path: latest_pipeline_path
        }
      end

      private

      def features
        scan_types.map do |scan_type|
          if auto_devops_source?
            scan(scan_type, configured: true)
          elsif latest_builds_reports.include?(scan_type)
            scan(scan_type, configured: true)
          else
            scan(scan_type, configured: false)
          end
        end
      end

      def latest_builds_reports
        strong_memoize(:reports) do
          latest_security_builds.map do |build|
            if Feature.enabled?(:ci_build_metadata_config)
              build.metadata.config_options[:artifacts][:reports].keys.map(&:to_sym)
            else
              build.options[:artifacts][:reports].keys
            end
          end.flatten
        end
      end

      def latest_security_builds
        return [] unless latest_default_branch_pipeline

        ::Security::SecurityJobsFinder.new(pipeline: latest_default_branch_pipeline).execute +
          ::Security::LicenseManagementJobsFinder.new(pipeline: latest_default_branch_pipeline).execute
      end

      def latest_default_branch_pipeline
        strong_memoize(:pipeline) { latest_pipeline_for_ref }
      end

      def latest_pipeline_path
        return help_page_path('ci/pipelines') unless latest_default_branch_pipeline

        project_pipeline_path(self, latest_default_branch_pipeline)
      end

      def scan(type, configured: false)
        {
          configured: configured,
          description: SCAN_DESCRIPTIONS[type],
          link: help_page_path(SCAN_DOCS[type]),
          name: SCAN_NAMES[type]
        }
      end

      def auto_devops_source?
        latest_default_branch_pipeline&.auto_devops_source?
      end

      def scan_types
        ::Security::SecurityJobsFinder.allowed_job_types + ::Security::LicenseManagementJobsFinder.allowed_job_types
      end
    end
  end
end
