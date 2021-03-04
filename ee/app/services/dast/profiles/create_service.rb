# frozen_string_literal: true

module Dast
  module Profiles
    class CreateService < BaseContainerService
      def execute
        return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?

        dast_profile = Dast::Profile.create!(
          project: container,
          name: params.fetch(:name),
          description: params.fetch(:description),
          branch_name: params[:branch_name],
          dast_site_profile: dast_site_profile,
          dast_scanner_profile: dast_scanner_profile
        )

        return ServiceResponse.success(payload: { dast_profile: dast_profile, pipeline_url: nil }) unless params.fetch(:run_after_create)

        response = ::DastOnDemandScans::CreateService.new(
          container: container,
          current_user: current_user,
          params: {
            dast_site_profile: dast_site_profile,
            dast_scanner_profile: dast_scanner_profile
          }
        ).execute

        return response if response.error?

        ServiceResponse.success(payload: { dast_profile: dast_profile, pipeline_url: response.payload.fetch(:pipeline_url) })
      rescue ActiveRecord::RecordInvalid => err
        ServiceResponse.error(message: err.record.errors.full_messages)
      rescue KeyError => err
        ServiceResponse.error(message: err.message.capitalize)
      end

      private

      def allowed?
        container.feature_available?(:security_on_demand_scans) &&
          Feature.enabled?(:dast_saved_scans, container, default_enabled: :yaml)
      end

      def dast_site_profile
        @dast_site_profile ||= params.fetch(:dast_site_profile)
      end

      def dast_scanner_profile
        @dast_scanner_profile ||= params.fetch(:dast_scanner_profile)
      end
    end
  end
end
