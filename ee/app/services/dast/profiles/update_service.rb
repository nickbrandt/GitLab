# frozen_string_literal: true

module Dast
  module Profiles
    class UpdateService < BaseContainerService
      include Gitlab::Utils::StrongMemoize

      def execute
        return unauthorized unless allowed?
        return error('Profile parameter missing') unless dast_profile
        return error(dast_profile.errors.full_messages) unless dast_profile.update(dast_profile_params)

        return success(dast_profile: dast_profile, pipeline_url: nil) unless params[:run_after_update]

        response = create_scan(dast_profile)

        return response if response.error?

        success(dast_profile: dast_profile, pipeline_url: response.payload.fetch(:pipeline_url))
      end

      private

      def allowed?
        container.feature_available?(:security_on_demand_scans) &&
          Feature.enabled?(:dast_saved_scans, container, default_enabled: :yaml) &&
          can?(current_user, :create_on_demand_dast_scan, container)
      end

      def error(message, opts = {})
        ServiceResponse.error(message: message, **opts)
      end

      def success(payload)
        ServiceResponse.success(payload: payload)
      end

      def unauthorized
        error('You are not authorized to update this profile', http_status: 403)
      end

      def dast_profile
        params[:dast_profile]
      end

      def dast_profile_params
        params.slice(:dast_site_profile_id, :dast_scanner_profile_id, :name, :description, :branch_name)
      end

      def create_scan(dast_profile)
        params = {
          dast_site_profile: dast_profile.dast_site_profile,
          dast_scanner_profile: dast_profile.dast_scanner_profile
        }

        ::DastOnDemandScans::CreateService.new(
          container: container,
          current_user: current_user,
          params: params
        ).execute
      end
    end
  end
end
