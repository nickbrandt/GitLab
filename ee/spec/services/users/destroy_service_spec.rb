# frozen_string_literal: true

require 'spec_helper'

describe Users::DestroyService do
  let(:current_user) { create(:admin) }

  subject(:service) { described_class.new(current_user) }

  describe '#execute' do
    let(:user) { create(:user) }

    describe 'audit events' do
      before do
        stub_licensed_features(admin_audit_log: true)
      end

      context 'when hard_delete' do
        let(:hard_delete) { true }

        it 'logs audit event' do
          expected_message = "Removed user"

          expect do
            service.execute(user, hard_delete: hard_delete)
          end.to change { AuditEvent.count }.by(1)

          expect(AuditEvent.last.present.action).to eq(expected_message)
        end
      end
    end
  end
end
