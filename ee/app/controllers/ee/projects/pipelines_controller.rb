# frozen_string_literal: true

module EE
  module Projects
    module PipelinesController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      def security
        if pipeline.expose_security_dashboard?
          render_show
        else
          redirect_to pipeline_path(pipeline)
        end
      end

      def licenses
        report_exists = pipeline.expose_license_scanning_data?

        respond_to do |format|
          if report_exists
            format.html { render_show }
            format.json do
              data = LicenseScanningReportsSerializer.new(project: project, current_user: current_user).represent(pipeline&.license_scanning_report&.licenses)
              render json: data, status: :ok
            end
          else
            format.html { redirect_to pipeline_path(pipeline) }
            format.json { head :not_found }
          end
        end
      end
    end
  end
end
