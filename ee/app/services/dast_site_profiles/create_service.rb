# frozen_string_literal: true

module DastSiteProfiles
  class CreateService < BaseService
    def execute(name: nil, target_url: nil)
      return ServiceResponse.error(message: 'Insufficient permissions') unless allowed?

      ServiceResponse.error(message: 'Not implemented')
    end

    def allowed?
      Ability.allowed?(current_user, :run_ondemand_dast_scan, project)
    end
  end
end
