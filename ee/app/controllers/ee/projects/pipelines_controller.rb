# frozen_string_literal: true

module EE
  module Projects
    module PipelinesController
      extend ::Gitlab::Utils::Override

      def security
        if pipeline.expose_security_dashboard?
          render_show
        else
          redirect_to pipeline_path(pipeline)
        end
      end

      def licenses
        if pipeline.expose_license_management_data?
          render_show
        else
          redirect_to pipeline_path(pipeline)
        end
      end

      override :show_represent_params
      def show_represent_params
        super.merge(expanded: params[:expanded].to_a.map(&:to_i))
      end
    end
  end
end
