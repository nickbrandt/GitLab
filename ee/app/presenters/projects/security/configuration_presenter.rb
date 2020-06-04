# frozen_string_literal: true

module Projects
  module Security
    class ConfigurationPresenter < Gitlab::View::Presenter::Delegated
      include Gitlab::Utils::StrongMemoize

      presents :project

      SCAN_DOCS = {
        container_scanning: 'user/application_security/container_scanning/index',
        dast: 'user/application_security/dast/index',
        dependency_scanning: 'user/application_security/dependency_scanning/index',
        license_management: 'user/compliance/license_compliance/index',
        license_scanning: 'user/compliance/license_compliance/index',
        sast: 'user/application_security/sast/index',
        secret_detection: 'user/application_security/secret_detection/index'
      }.freeze

      def self.localized_scan_descriptions
        {
          container_scanning: _('Check your Docker images for known vulnerabilities.'),
          dast: _('Analyze a review version of your web application.'),
          dependency_scanning: _('Analyze your dependencies for known vulnerabilities.'),
          license_management: _('Search your project dependencies for their licenses and apply policies.'),
          license_scanning: _('Search your project dependencies for their licenses and apply policies.'),
          sast: _('Analyze your source code for known vulnerabilities.'),
          secret_detection: _('Analyze your source code and git history for secrets')
        }.freeze
      end

      def self.localized_scan_names
        {
          container_scanning: _('Container Scanning'),
          dast: _('Dynamic Application Security Testing (DAST)'),
          dependency_scanning: _('Dependency Scanning'),
          license_management: 'License Management',
          license_scanning: _('License Compliance'),
          sast: _('Static Application Security Testing (SAST)'),
          secret_detection: _('Secret Detection')
        }.freeze
      end

      def to_h
        {
          auto_devops_enabled: auto_devops_source?,
          auto_devops_help_page_path: help_page_path('topics/autodevops/index'),
          features: features.to_json,
          help_page_path: help_page_path('user/application_security/index'),
          latest_pipeline_path: latest_pipeline_path,
          auto_fix_enabled: {
            dependency_scanning: true,
            container_scanning: true
          }.to_json,
          can_toggle_auto_fix_settings: auto_fix_permission,
          auto_fix_user_path: '/' # TODO: real link will be updated with https://gitlab.com/gitlab-org/gitlab/-/issues/215669
        }
      end

      private

      def features
        scans = scan_types.map do |scan_type|
          if auto_devops_source?
            scan(scan_type, configured: true)
          elsif latest_builds_reports.include?(scan_type)
            scan(scan_type, configured: true)
          else
            scan(scan_type, configured: false)
          end
        end

        # TODO: remove this line with #8912
        license_compliance_substitute(scans)
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
          ::Security::LicenseComplianceJobsFinder.new(pipeline: latest_default_branch_pipeline).execute
      end

      def latest_default_branch_pipeline
        strong_memoize(:pipeline) { latest_pipeline_for_ref }
      end

      def latest_pipeline_path
        return help_page_path('ci/pipelines') unless latest_default_branch_pipeline

        project_pipeline_path(self, latest_default_branch_pipeline)
      end

      # In this method we define if License Compliance feature is configured
      # by looking into `license_scanning` and `license_management` reports
      # in 13.0 support for `license_management` report type is scheduled to be dropped.
      # With this change we won't need this method anymore.
      def license_compliance_substitute(scans)
        license_management = scans.find { |scan_type| scan_type[:name] == localized_scan_names[:license_management] }
        license_compliance_config = license_management.fetch(:configured, false)

        scans.delete(license_management)

        if license_compliance_config
          scans.map do |scan_type|
            scan_type[:configured] = true if scan_type[:name] == _('License Compliance')
          end
        end

        scans
      end

      def scan(type, configured: false)
        {
          configured: configured,
          description: self.class.localized_scan_descriptions[type],
          link: help_page_path(SCAN_DOCS[type]),
          name: localized_scan_names[type]
        }
      end

      def auto_devops_source?
        latest_default_branch_pipeline&.auto_devops_source?
      end

      def scan_types
        ::Security::SecurityJobsFinder.allowed_job_types + ::Security::LicenseComplianceJobsFinder.allowed_job_types
      end

      def localized_scan_names
        @localized_scan_names ||= self.class.localized_scan_names
      end
    end
  end
end
