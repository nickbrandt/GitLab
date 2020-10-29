# frozen_string_literal: true

module Projects
  module Security
    class VulnerabilitiesController < Projects::ApplicationController
      include SecurityDashboardsPermissions
      include IssuableActions
      include RendersNotes

      before_action :vulnerability, except: :index

      alias_method :vulnerable, :project

      feature_category :vulnerability_management

      def show
        pipeline = vulnerability.finding.pipelines.first
        @pipeline = pipeline if Ability.allowed?(current_user, :read_pipeline, pipeline)
        @gfm_form = true
      end

      def new_issue
        @project = vulnerability.project

        issue_params = {
          title: "Investigate vulnerability: #{vulnerability.title}",
          description: render_description(vulnerability),
          confidential: true
        }

        @issue = @notable = ::Issues::BuildService
          .new(@project, current_user, issue_params).execute

        render '/projects/issues/new'
      end

      private

      def vulnerability
        @issuable = @noteable = @vulnerability ||= vulnerable.vulnerabilities.find(params[:id])
      end

      alias_method :issuable, :vulnerability
      alias_method :noteable, :vulnerability

      def issue_serializer
        IssueSerializer.new(current_user: current_user)
      end

      def render_description(vulnerability)
        ApplicationController.render(
          template: 'vulnerabilities/issue_description.md.erb',
          locals: { vulnerability: vulnerability.present }
        )
      end
    end
  end
end
