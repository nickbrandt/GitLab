# frozen_string_literal: true

module API
  class Vulnerabilities < Grape::API
    include PaginationParams

    helpers ::API::Helpers::VulnerabilityFindingsHelpers

    helpers do
      def vulnerabilities_by(project, params)
        Security::VulnerabilitiesFinder.new(project, params).execute
      end
    end

    before do
      authenticate!
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      params do
        # These params have no effect for Vulnerabilities API but are required to support falling back to
        # responding with Vulnerability Findings when :first_class_vulnerabilities feature is disabled.
        # TODO: remove usage of :vulnerability_findings_params when feature flag is removed
        # https://gitlab.com/gitlab-org/gitlab/issues/33488
        use :vulnerability_findings_params
      end
      desc 'Get a list of project vulnerabilities' do
        success VulnerabilityEntity
      end
      get ':id/vulnerabilities' do
        if Feature.enabled?(:first_class_vulnerabilities)
          authorize! :read_project_security_dashboard, user_project

          vulnerabilities = paginate(
            vulnerabilities_by(user_project, declared_params)
          )

          present vulnerabilities, with: VulnerabilityEntity
        else
          respond_with_vulnerability_findings
        end
      end
    end
  end
end
