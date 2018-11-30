# frozen_string_literal: true

module EE::Projects::DisableDeployKeyService
  extend ActiveSupport::Concern
  extend ::Gitlab::Utils::Override

  override :execute
  def execute
    super.tap do |deploy_key_project|
      break unless deploy_key_project

      log_audit_event(deploy_key_project.deploy_key.title, action: :destroy)
    end
  end

  private

  def log_audit_event(key_title, options = {})
    AuditEventService.new(current_user, project, options)
      .for_deploy_key(key_title).security_event
  end
end
