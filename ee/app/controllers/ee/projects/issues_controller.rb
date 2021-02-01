# frozen_string_literal: true

module EE
  module Projects
    module IssuesController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        include DescriptionDiffActions

        before_action :whitelist_query_limiting_ee, only: [:update]
        before_action only: [:new, :create] do
          populate_vulnerability_id
        end

        feature_category :issue_tracking, [:delete_description_version, :description_diff]
      end

      private

      def issue_params_attributes
        attrs = super
        attrs.unshift(:weight) if project.feature_available?(:issue_weights)
        attrs.unshift(:epic_id) if project.group&.feature_available?(:epics)

        attrs
      end

      override :finder_options
      def finder_options
        options = super

        return super if project.feature_available?(:issue_weights)

        options.reject { |key| key == 'weight' }
      end

      def whitelist_query_limiting_ee
        ::Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab/issues/4794')
      end

      def issue_params
        super.tap do |params|
          if vulnerability_id
            params.merge!(vulnerability_issue_build_parameters)
          end
        end
      end

      def create_vulnerability_issue_feedback(issue)
        return unless issue.persisted? && vulnerability

        feedback_params = {
          issue: issue,
          feedback_type: 'issue',
          category: vulnerability.report_type,
          project_fingerprint: vulnerability.finding.project_fingerprint,
          vulnerability_data: vulnerability.as_json
        }

        feedback_params[:vulnerability_data][:vulnerability_id] = vulnerability.id

        result = VulnerabilityFeedback::CreateService.new(
          issue.project,
          current_user,
          feedback_params
        ).execute

        result[:message].each do |attribute, error|
          flash[:alert] = render_vulnerability_link_alert(error)
        end
      end

      def vulnerability
        project.vulnerabilities.find(vulnerability_id) if vulnerability_id
      end

      def vulnerability_issue_build_parameters
        issue = params[:issue]

        {
          title: issue.fetch(:title, _("Investigate vulnerability: %{title}") % { title: vulnerability.title }),
          description: issue.fetch(:description, render_vulnerability_description),
          confidential: issue.fetch(:confidential, true)
        }
      end

      def render_vulnerability_description
        render_to_string(
          template: 'vulnerabilities/issue_description.md.erb',
          locals: { vulnerability: vulnerability.present }
        )
      end

      def render_vulnerability_link_alert(error_message)
        render_to_string(
          partial: 'vulnerabilities/unable_to_link_vulnerability.html.haml',
          locals: {
            vulnerability_link: vulnerability_path(vulnerability),
            error_message: error_message
          }
        )
      end

      def populate_vulnerability_id
        self.vulnerability_id = params[:vulnerability_id] if can?(current_user, :read_vulnerability, project)
      end
    end
  end
end
