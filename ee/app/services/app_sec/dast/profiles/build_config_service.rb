# frozen_string_literal: true

module AppSec
  module Dast
    module Profiles
      class BuildConfigService < BaseProjectService
        def execute
          return ServiceResponse.error(message: 'Insufficient permissions for dast_configuration keyword') unless allowed?

          build_config = { dast_site_profile: site_profile, dast_scanner_profile: scanner_profile }

          return ServiceResponse.error(message: errors) unless errors.empty?

          ServiceResponse.success(payload: build_config)
        end

        private

        def allowed?
          can?(current_user, :create_on_demand_dast_scan, project) &&
            ::Feature.enabled?(:dast_configuration_ui, project, default_enabled: :yaml)
        end

        def errors
          @errors ||= []
        end

        def site_profile
          fetch_profile(params[:dast_site_profile]) do |name|
            DastSiteProfilesFinder.new(project_id: project.id, name: name)
          end
        end

        def scanner_profile
          fetch_profile(params[:dast_scanner_profile]) do |name|
            DastScannerProfilesFinder.new(project_ids: [project.id], name: name)
          end
        end

        def fetch_profile(name)
          return unless name

          profile = yield(name).execute.first

          unless profile && can?(current_user, :read_on_demand_scans, profile)
            errors.append("DAST profile not found: #{name}")
            return
          end

          profile
        end
      end
    end
  end
end
