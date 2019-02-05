# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::CreateService do
  include ProjectForksHelper

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user, opts) }
  let(:opts) do
    {
      title: 'Awesome merge_request',
      description: 'please fix',
      source_branch: 'feature',
      target_branch: 'master',
      force_remove_source_branch: '1'
    }
  end

  before do
    project.add_maintainer(user)
    allow(service).to receive(:execute_hooks)
  end

  describe '#execute' do
    context 'code owners' do
      it 'refreshes code owners for the merge request' do
        fake_refresh_service = instance_double(::MergeRequests::SyncCodeOwnerApprovalRules)

        expect(::MergeRequests::SyncCodeOwnerApprovalRules)
          .to receive(:new).with(kind_of(MergeRequest)).and_return(fake_refresh_service)
        expect(fake_refresh_service).to receive(:execute)

        service.execute
      end

      context 'when multiple code owner rules is disabled' do
        let!(:owners) { create_list(:user, 2) }

        before do
          stub_feature_flags(multiple_code_owner_rules: false)
          allow(::Gitlab::CodeOwners).to receive(:for_merge_request).and_return(owners)
        end

        it 'syncs code owner to approval rule' do
          merge_request = service.execute

          rule = merge_request.approval_rules.code_owner.first

          expect(rule.users).to contain_exactly(*owners)
        end
      end
    end
  end
end
