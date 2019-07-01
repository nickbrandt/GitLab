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
    it 'refreshes code owners for the merge request' do
      fake_refresh_service = instance_double(::MergeRequests::SyncCodeOwnerApprovalRules)

      expect(::MergeRequests::SyncCodeOwnerApprovalRules)
        .to receive(:new).with(kind_of(MergeRequest)).and_return(fake_refresh_service)
      expect(fake_refresh_service).to receive(:execute)

      service.execute
    end

    it_behaves_like 'new issuable with scoped labels' do
      let(:parent) { project }
    end
  end
end
