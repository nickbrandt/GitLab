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
      let!(:owners) { create_list(:user, 2) }

      before do
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
