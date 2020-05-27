# frozen_string_literal: true

module AuditLogsHelper
  def admin_audit_log_token_types
    %w[User Group Project].freeze
  end
end
