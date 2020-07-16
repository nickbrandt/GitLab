# frozen_string_literal: true

module Projects
  module Security
    class ScannedResourcesController < ::Projects::ApplicationController
      before_action :authorize_read_vulnerability!
      before_action :scanned_resources

      def index
        respond_to do |format|
          format.csv do
            send_data(
              render_csv,
              type: 'text/csv; charset=utf-8'
            )
          end
        end
      end

      private

      def scanned_resources
        pipeline = project.ci_pipelines.find(pipeline_id)
        @scanned_resources = pipeline&.security_reports&.reports&.fetch('dast', nil)&.scanned_resources

        return if @scanned_resources

        render_404
      end

      def render_csv
        CsvBuilders::SingleBatch.new(
          ::Gitlab::Ci::Parsers::Security::ScannedResources.new.scanned_resources_for_csv(@scanned_resources),
          {
            'Method': 'request_method',
            'Scheme': 'scheme',
            'Host': 'host',
            'Port': 'port',
            'Path': 'path',
            'Query String': 'query_string'
          }
        ).render
      end

      def pipeline_id
        params.require(:pipeline_id)
      end

      def authorize_read_vulnerability!
        return if can?(current_user, :read_vulnerability, project)

        render_404
      end
    end
  end
end
