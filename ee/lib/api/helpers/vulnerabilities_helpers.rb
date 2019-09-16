# frozen_string_literal: true

module API
  module Helpers
    module VulnerabilitiesHelpers
      def find_source(source_type, id)
        public_send("find_#{source_type}!", id) # rubocop:disable GitlabSecurity/PublicSend
      end

      def authorize_source!(source_type, source)
        authorize! :"read_#{source_type}_security_dashboard", source
      end

      def vulnerability_occurrences_by(params)
        if params[:pipeline_id].present?
          find_vulnerabilities_for_pipeline(params)
        elsif params[:source_type] == 'group'
          find_vulnerabilities_for_group(params)
        elsif params[:source_type] == 'project'
          find_vulnerabilities_for_project(params)
        else
          []
        end
      end

      def find_vulnerabilities_for_pipeline(params)
        pipeline = params[:source].all_pipelines.find_by(id: params[:pipeline_id]) # rubocop:disable CodeReuse/ActiveRecord
        Security::PipelineVulnerabilitiesFinder.new(pipeline: pipeline, params: params).execute
      end

      def find_vulnerabilities_for_project(params)
        pipeline = params[:source].latest_pipeline_with_security_reports
        Security::PipelineVulnerabilitiesFinder.new(pipeline: pipeline, params: params).execute
      end

      def find_vulnerabilities_for_group(params)
        Security::VulnerabilitiesFinder.new(params[:source], params: params).execute(:with_sha)
      end
    end
  end
end
