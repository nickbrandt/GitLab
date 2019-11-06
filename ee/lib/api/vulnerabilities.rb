# frozen_string_literal: true

module API
  class Vulnerabilities < Grape::API
    include PaginationParams

    helpers do
      def vulnerabilities_by(project)
        Security::VulnerabilitiesFinder.new(project).execute
      end

      def find_vulnerability!
        Vulnerability.with_findings.find(params[:id])
      end

      def find_and_authorize_vulnerability!(action)
        find_vulnerability!.tap do |vulnerability|
          authorize! action, vulnerability.project
        end
      end

      def render_vulnerability(vulnerability)
        if vulnerability.valid?
          present vulnerability, with: EE::API::Entities::Vulnerability
        else
          render_validation_error!(vulnerability)
        end
      end
    end

    before do
      not_found! unless Feature.enabled?(:first_class_vulnerabilities)

      authenticate!
    end

    params do
      requires :id, type: String, desc: 'The ID of a vulnerability'
    end
    resource :vulnerabilities do
      desc 'Resolve a vulnerability' do
        success EE::API::Entities::Vulnerability
      end
      post ':id/resolve' do
        vulnerability = find_and_authorize_vulnerability!(:resolve_vulnerability)
        break not_modified! if vulnerability.closed?

        vulnerability = ::Vulnerabilities::ResolveService.new(current_user, vulnerability).execute
        render_vulnerability(vulnerability)
      end

      desc 'Dismiss a vulnerability' do
        success EE::API::Entities::Vulnerability
      end
      post ':id/dismiss' do
        vulnerability = find_and_authorize_vulnerability!(:dismiss_vulnerability)
        break not_modified! if vulnerability.closed?

        vulnerability = ::Vulnerabilities::DismissService.new(current_user, vulnerability).execute
        render_vulnerability(vulnerability)
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of project vulnerabilities' do
        success EE::API::Entities::Vulnerability
      end
      get ':id/vulnerabilities' do
        authorize! :read_project_security_dashboard, user_project

        vulnerabilities = paginate(
          vulnerabilities_by(user_project)
        )

        present vulnerabilities, with: EE::API::Entities::Vulnerability
      end
    end
  end
end
