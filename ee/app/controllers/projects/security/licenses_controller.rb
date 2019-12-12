# frozen_string_literal: true

module Projects
  module Security
    class LicensesController < Projects::ApplicationController
      before_action :authorize_read_licenses!, only: [:index]
      before_action :authorize_admin_software_license_policy!, only: [:create, :update]

      def index
        respond_to do |format|
          format.json do
            ::Gitlab::UsageDataCounters::LicensesList.count(:views)

            license_compliance = project.license_compliance
            render json: serializer.represent(
              pageable(license_compliance.policies),
              build: license_compliance.latest_build_for_default_branch
            )
          end
        end
      end

      def create
        result = ::Projects::Licenses::CreatePolicyService
          .new(project, current_user, software_license_policy_params)
          .execute

        if result[:status] == :success
          render json: LicenseEntity.represent(result[:software_license_policy]), status: :created
        else
          render_error_for(result)
        end
      end

      def update
        result = ::Projects::Licenses::UpdatePolicyService
          .new(project, current_user, software_license_policy_params)
          .execute(params[:id])

        if result[:status] == :success
          render json: LicenseEntity.represent(result[:software_license_policy]), status: :ok
        else
          render_error_for(result)
        end
      end

      private

      def serializer
        ::LicensesListSerializer.new(project: project, user: current_user)
          .with_pagination(request, response)
      end

      def pageable(items)
        ::Gitlab::ItemsCollection.new(items)
      end

      def software_license_policy_params
        params.require(:software_license_policy).permit(:software_license_id, :spdx_identifier, :classification)
      end

      def render_error_for(result)
        render json: { errors: result[:message].as_json }, status: result.fetch(:http_status, :unprocessable_entity)
      end
    end
  end
end
