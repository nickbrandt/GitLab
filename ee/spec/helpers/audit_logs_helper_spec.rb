# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditLogsHelper do
  using RSpec::Parameterized::TableSyntax

  describe '#admin_audit_log_token_types' do
    it 'returns the available tokens' do
      available_tokens = %w[User Group Project]
      expect(admin_audit_log_token_types).to eq(available_tokens)
    end
  end
end
