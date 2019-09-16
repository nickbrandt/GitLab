# frozen_string_literal: true

module API
  class Vulnerabilities < Grape::API
    include PaginationParams

    before { authenticate! }

    helpers ::API::Helpers::VulnerabilitiesHelpers

    %w[group project].each do |source_type|
      resource source_type.pluralize, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Get a list of group or project vulnerabilities' do
          success ::Vulnerabilities::OccurrenceEntity
        end

        params do
          requires :id, type: String, desc: "The #{source_type} ID"
          optional :report_type, type: Array[String], desc: 'The type of report vulnerability belongs to', default: ::Vulnerabilities::Occurrence.report_types.keys
          optional :scope, type: String, desc: 'Return vulnerabilities for the given scope: `dismissed` or `all`', default: 'dismissed', values: %w[all dismissed]
          optional :severity,
                   type: Array[String],
                   desc: 'Returns issues belonging to specified severity level: `undefined`, `info`, `unknown`, `low`, `medium`, `high`, or `critical`. Defaults to all',
                   default: ::Vulnerabilities::Occurrence.severities.keys
          optional :confidence,
                   type: Array[String],
                   desc: 'Returns vulnerabilities belonging to specified confidence level: `undefined`, `ignore`, `unknown`, `experimental`, `low`, `medium`, `high`, or `confirmed`. Defaults to all',
                   default: ::Vulnerabilities::Occurrence.confidences.keys
          optional :pipeline_id, type: String, desc: 'The ID of the pipeline'

          use :pagination
        end

        get ':id/vulnerabilities' do
          source = find_source(source_type, declared_params[:id])
          authorize_source!(source_type, source)

          vulnerability_occurrences = paginate(
            Kaminari.paginate_array(
              vulnerability_occurrences_by(
                declared_params.merge(source_type: source_type, source: source)
              )
            )
          )

          Gitlab::Vulnerabilities::OccurrencesPreloader.preload_feedback!(vulnerability_occurrences)

          present vulnerability_occurrences,
            with: ::Vulnerabilities::OccurrenceEntity,
            request: GrapeRequestProxy.new(request, current_user)
        end
      end
    end
  end
end
