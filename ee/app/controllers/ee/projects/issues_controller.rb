# frozen_string_literal: true

module EE
  module Projects
    module IssuesController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        include DescriptionDiffActions

        before_action :whitelist_query_limiting_ee, only: [:update]

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

      def create_vulnerability_issue_link(issue)
        return unless params[:vulnerability_id]

        vulnerability = project.vulnerabilities.find(params[:vulnerability_id])

        result = VulnerabilityIssueLinks::CreateService.new(
          current_user,
          vulnerability,
          issue,
          link_type: Vulnerabilities::IssueLink.link_types[:created]
        ).execute

        flash[:notice] = _('Unable to create link to vulnerability') if result.status == :error
      end
    end
  end
end
