# frozen_string_literal: true

require 'vulnerabilities/occurrence_serializer'

module Gitlab
  module Vulnerabilities
    class Occurence
      attr_reader :vulnerable, :params, :user, :request, :response

      def initialize(vulnerable, params, user, request, response)
        @vulnerable = vulnerable
        @params = params
        @user = user
        @request = request
        @response = response
      end

      def findings
        return cached_vulnerabilities_findings unless dynamic_filters_included?

        ::Vulnerabilities::OccurrenceSerializer
          .new(current_user: user)
          .with_pagination(request, response)
          .represent(
            vulnerability_findings.ordered.page(params[:page]),
            preload: true
          )
      end

      private

      def filter_params
        params.permit(:scope, report_type: [], confidence: [], project_id: [], severity: [])
      end

      def vulnerability_findings
        ::Security::VulnerabilityFindingsFinder.new(vulnerable, params: filter_params).execute(:with_sha)
      end

      def cached_vulnerabilities_findings
        #f = ::Vulnerabilities::OccurrenceSerializer.new(current_user: user).with_pagination(request, response).represent(vulnerability_findings.ordered.page(params[:page]), preload: true)
        results = []
        project_ids_to_fetch.each do |project_id|
          results += Gitlab::Vulnerabilities::OccurenceCache.new(vulnerable, project_id).fetch
        end

        results
      end

      def dynamic_filters_included?
        dynamic_filters = [:report_type, :confidence, :severity, :project_id, :page]
        params.keys.any? { |k| dynamic_filters.include? k.to_sym }
      end

      def project_ids_to_fetch
        project_ids = vulnerable.is_a?(Project) ? [vulnerable.id] : []

        return filter_params[:project_id] + project_ids if filter_params.key?('project_id')

        vulnerable.is_a?(Group) ? vulnerable.project_ids_with_security_reports : []
      end
    end
  end
end
