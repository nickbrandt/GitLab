# frozen_string_literal: true

module EE::Projects::EnableDeployKeyService
  extend ActiveSupport::Concern
  extend ::Gitlab::Utils::Override

  override :execute
  def execute
    super.tap do |key|
      break unless key

      log_audit_event(key.title, action: :create)
    end
  end

  private

  def log_audit_event(key_title, options = {})
    AuditEventService.new(current_user, project, options)
      .for_deploy_key(key_title).security_event
  end
end
