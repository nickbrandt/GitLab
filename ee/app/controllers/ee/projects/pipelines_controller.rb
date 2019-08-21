# frozen_string_literal: true

module EE
  module Projects
    module PipelinesController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        # Since feature flags are pushed only once on page load, we need to
        # ensure they're pushed for all tabs in the pipelines view. This is
        # because the user can freely navigate between them *without*
        # triggering a page load.
        before_action only: [:show, :builds, :failures, :security, :licenses] do
          push_frontend_feature_flag(:pipeline_report_api)
        end
      end

      def security
        if pipeline.expose_security_dashboard?
          render_show
        else
          redirect_to pipeline_path(pipeline)
        end
      end

      def licenses
        report_exists = pipeline.expose_license_management_data?

        respond_to do |format|
          if report_exists
            format.html { render_show }
            format.json do
              render json: LicenseManagementReportLicenseEntity.licenses_payload(pipeline.license_management_report), status: :ok
            end
          else
            format.html { redirect_to pipeline_path(pipeline) }
            format.json { head :not_found }
          end
        end
      end

      override :show_represent_params
      def show_represent_params
        super.merge(expanded: params[:expanded].to_a.map(&:to_i))
      end
    end
  end
end
