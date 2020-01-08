# frozen_string_literal: true

require 'vulnerabilities/occurrence_serializer'

module Gitlab
  module Vulnerabilities
    class Occurrence
      attr_reader :vulnerable, :params, :user, :request, :response

      def initialize(vulnerable, params, user, request, response)
        @vulnerable = vulnerable
        @params = params
        @user = user
        @request = request
        @response = response
      end

      def findings
        return cached_vulnerabilities_findings if use_vulnerability_cache?

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
        ::Security::VulnerabilityFindingsFinder
          .new(vulnerable, params: filter_params)
          .execute(:with_sha)
      end

      def cached_vulnerabilities_findings
        occurrences = []

        project_ids_to_fetch.each do |project_id|
          occurrences += Gitlab::Vulnerabilities::OccurrenceCache
            .new(vulnerable, project_id, user)
            .fetch
        end

        paginate occurrences
      end

      def paginate(occurrences)
        page = params[:page].nil? ? 1 : params[:page].to_i
        per_page = ::Vulnerabilities::Occurrence.page(1).limit_value
        first_index = (page - 1) * per_page
        last_index = (page * per_page) - 1

        order(occurrences)[first_index..last_index]
      end

      def order(vulnerabilities)
        ordered = vulnerabilities.sort do |a, b|
          [
            ::Vulnerabilities::Occurrence::SEVERITY_LEVELS[b['severity']],
            ::Vulnerabilities::Occurrence::CONFIDENCE_LEVELS[b['confidence']],
            a['id']
          ] <=> [
            ::Vulnerabilities::Occurrence::SEVERITY_LEVELS[a['severity']],
            ::Vulnerabilities::Occurrence::CONFIDENCE_LEVELS[a['confidence']],
            b['id']
          ]
        end
      end

      def use_vulnerability_cache?
        Feature.enabled?(:cache_vulnerability_occurrence, vulnerable) && !dynamic_filters_included?
      end

      def dynamic_filters_included?
        dynamic_filters = [:report_type, :confidence, :severity, :project_id]

        params.keys.any? { |k| dynamic_filters.include? k.to_sym }
      end

      def project_ids_to_fetch
        project_id = vulnerable.is_a?(Project) ? [vulnerable.id] : []

        project_id + if filter_params.key?('project_id')
                       filter_params[:project_id]
                     else
                       vulnerable.is_a?(Group) ? vulnerable.project_ids_with_security_reports : []
                     end
      end
    end
  end
end
