# frozen_string_literal: true

require 'spec_helper'

describe AlertManagement::UpdateAlertStatusService do
  let(:project) { alert.project }
  let_it_be(:user) { build(:user) }

  let_it_be(:alert, reload: true) do
    create(:alert_management_alert, :triggered)
  end

  let(:service) { described_class.new(alert, user, status: new_status, ended_at: ended_at) }

  describe '#execute' do
    shared_examples 'update failure' do |error_message|
      it 'returns an error' do
        expect(response).to be_error
        expect(response.message).to eq(error_message)
        expect(response.payload[:alert]).to eq(alert)
      end

      it 'does not update the status' do
        expect { response }.not_to change { alert.status }
      end
    end

    shared_examples 'updating the status' do
      it 'returns success' do
        expect(response).to be_success
        expect(response.payload[:alert]).to eq(alert)
      end

      it 'updates the status' do
        response
        expect(alert.reload.status).to eq(new_status)
      end
    end

    let(:status_name) { 'ACKNOWLEDGED' }
    let(:new_status) { Types::AlertManagement::StatusEnum.values[status_name].value }
    let(:ended_at) { 1.day.ago }
    let(:can_update) { true }

    subject(:response) { service.execute }

    before do
      allow(user).to receive(:can?)
        .with(:update_alert_management_alert, project)
        .and_return(can_update)
    end

    %w(TRIGGERED ACKNOWLEDGED IGNORED).each do |status_name|
      describe "with #{status_name} status" do
        it_behaves_like 'updating the status'

        it 'sets ended_at to nil' do
          response
          expect(alert.reload.ended_at).to be_nil
        end
      end
    end

    describe 'with RESOLVED status' do
      let(:status_name) { 'RESOLVED' }

      it_behaves_like 'updating the status'

      it 'sets ended_at correctly' do
        response
        expect(alert.reload.ended_at).to be_like_time(ended_at)
      end
    end

    context 'when user has no permissions' do
      let(:can_update) { false }

      include_examples 'update failure', _('You have no permissions')
    end

    context 'with no status' do
      let(:new_status) { nil }

      include_examples 'update failure', _('Invalid status')
    end

    context 'with unknown status' do
      let(:new_status) { -1 }

      include_examples 'update failure', _('Invalid status')
    end
  end
end
