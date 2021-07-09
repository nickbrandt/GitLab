# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestApprovalSettings::UpdateService do
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:params) { { allow_author_approval: true } }

  subject(:service) do
    described_class.new(
      container: group,
      current_user: user,
      params: params
    )
  end

  describe 'execute' do
    context 'user does not have permissions' do
      before do
        allow(service).to receive(:can?).with(user, :admin_merge_request_approval_settings, group).and_return(false)
      end

      it 'responds with an error response', :aggregate_failures do
        response = subject.execute

        expect(response.status).to eq(:error)
        expect(response.message).to eq('Insufficient permissions')
      end
    end

    context 'user has permissions' do
      before do
        allow(service).to receive(:can?).with(user, :admin_merge_request_approval_settings, group).and_return(true)
      end

      it 'creates a new setting' do
        expect { subject.execute }
          .to change { group.group_merge_request_approval_setting }
          .from(nil).to(be_instance_of(GroupMergeRequestApprovalSetting))
      end

      it 'responds with a successful service response', :aggregate_failures do
        response = subject.execute

        expect(response).to be_success
        expect(response.payload.allow_author_approval).to be(true)
      end

      context 'when group has an existing setting' do
        let_it_be(:group) { create(:group) }
        let_it_be(:existing_setting) { create(:group_merge_request_approval_setting, group: group) }

        it 'does not create a new setting' do
          expect { subject.execute }
            .to change { GroupMergeRequestApprovalSetting.count }.by(0)
            .and change { existing_setting.reload.allow_author_approval }.to(true)
        end

        it 'responds with a successful service response', :aggregate_failures do
          response = subject.execute

          expect(response).to be_success
          expect(response.payload.allow_author_approval).to be(true)
        end
      end

      context 'when saving fails' do
        let(:params) { { allow_author_approval: nil } }

        it 'responds with an error service response', :aggregate_failures do
          response = subject.execute

          expect(response).to be_error
          expect(response.message).to eq(allow_author_approval: ['must be a boolean value'])
        end
      end
    end
  end
end
