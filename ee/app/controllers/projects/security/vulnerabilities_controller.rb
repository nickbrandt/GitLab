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

      private

      def vulnerability
        @noteable = @issueable = @vulnerability ||= vulnerable.vulnerabilities.find(params[:id])
      end

      alias_method :issuable, :vulnerability
      alias_method :noteable, :vulnerability
    end
  end
end
