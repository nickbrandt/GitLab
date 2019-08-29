# frozen_string_literal: true

# Managed license creation service. For use in the managed license controller.
module SoftwareLicensePolicies
  class CreateService < ::BaseService
    def initialize(project, user, params)
      super(project, user, params.with_indifferent_access)
    end

    def execute
      return error("", 403) unless can?(@current_user, :admin_software_license_policy, @project)

      success(software_license_policy: create_software_license_policy)
    rescue StandardError => exception
      error(prepare_message_for(exception), 400)
    end

    private

    def create_software_license_policy
      policy = @project.add_software_license_policy_for(
        license_name: params[:name],
        classification: params[:approval_status]
      )
      RefreshLicenseComplianceChecksWorker.perform_async(@project.id)
      policy
    end

    def prepare_message_for(error)
      return error.record.errors.full_messages if error.respond_to?(:record)
      return error.model.errors.full_messages if error.respond_to?(:model)

      log_error(error.message)
      error.message
    end
  end
end
