# frozen_string_literal: true

module Projects
  module Operations
    class UpdateService < BaseService
      def execute
        Projects::UpdateService
          .new(project, current_user, project_update_params)
          .execute
      end

      private

      def project_update_params
        tracing_setting_params(params)
      end

      def tracing_setting_params(params)
        attr = params[:tracing_setting_attributes]
        return params unless attr

        destroy = attr[:external_url].blank?

        { tracing_setting_attributes: attr.merge(_destroy: destroy) }
      end
    end
  end
end
