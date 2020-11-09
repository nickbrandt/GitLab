# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::PushOptionsHandlerService do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user1) { create(:user, developer_projects: [project]) }
  let_it_be(:user2) { create(:user, developer_projects: [project]) }
  let_it_be(:user3) { create(:user, developer_projects: [project]) }
  let_it_be(:forked_project) { fork_project(project, user1, repository: true) }

  let(:service) { described_class.new(project, user1, changes, push_options) }
  let(:source_branch) { 'fix' }
  let(:new_branch_changes) { "#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{source_branch}" }
  let(:existing_branch_changes) { "d14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{source_branch}" }
  let(:error_mr_required) { "A merge_request.create push option is required to create a merge request for branch #{source_branch}" }

  before do
    stub_licensed_features(multiple_merge_request_assignees: true)
  end

  shared_examples_for 'a service that can create a merge request' do
    subject(:last_mr) { MergeRequest.last }

    it 'creates a merge request with the correct target branch' do
      branch = push_options[:target] || project.default_branch

      expect { service.execute }.to change { MergeRequest.count }.by(1)
      expect(last_mr.target_branch).to eq(branch)
    end

    context 'when project has been forked', :sidekiq_might_not_need_inline do
      let(:forked_project) { fork_project(project, user1, repository: true) }
      let(:service) { described_class.new(forked_project, user1, changes, push_options) }

      before do
        allow(forked_project).to receive(:empty_repo?).and_return(false)
      end

      it 'sets the correct source and target project' do
        service.execute

        expect(last_mr.source_project).to eq(forked_project)
        expect(last_mr.target_project).to eq(project)
      end
    end
  end

  shared_examples_for 'a service that does not create a merge request' do
    it do
      expect { service.execute }.not_to change { MergeRequest.count }
    end
  end

  # In the non-foss version of GitLab, there can be many assignees
  shared_examples_for 'a service that can change assignees of a merge request' do |count|
    subject(:last_mr) { MergeRequest.last }

    it 'changes assignee count' do
      service.execute

      expect(last_mr.assignees.count).to eq(count)
    end
  end

  describe '`assign` push option' do
    let(:push_options) { { assign: { user2.id => 1, user3.id => 1 } } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        service.execute

        expect(service.errors).to include(error_mr_required)
      end

      context 'when coupled with the `create` push option in ee' do
        let(:push_options) { { create: true, assign: { user2.id => 1, user3.id => 1 } } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can change assignees of a merge request', 2
      end
    end

    context 'with an existing branch but no open MR' do
      let(:changes) { existing_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        service.execute

        expect(service.errors).to include(error_mr_required)
      end

      context 'when coupled with the `create` push option in ee' do
        let(:push_options) { { create: true, assign: { user2.id => 1, user3.id => 1 } } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can change assignees of a merge request', 2
      end
    end

    context 'with an existing branch that has a merge request open in ee' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch)}

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can change assignees of a merge request', 2
    end
  end

  describe '`unassign` push option' do
    let(:push_options) { { assign: { user2.id => 1, user3.id => 1 }, unassign: { user1.id => 1, user3.id => 1 } } }

    context 'with a new branch' do
      let(:changes) { new_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        service.execute

        expect(service.errors).to include(error_mr_required)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, assign: { user2.id => 1, user3.id => 1 }, unassign: { user1.id => 1, user3.id => 1 } } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can change assignees of a merge request', 1
      end
    end

    context 'with an existing branch but no open MR' do
      let(:changes) { existing_branch_changes }

      it_behaves_like 'a service that does not create a merge request'

      it 'adds an error to the service' do
        service.execute

        expect(service.errors).to include(error_mr_required)
      end

      context 'when coupled with the `create` push option' do
        let(:push_options) { { create: true, assign: { user2.id => 1, user3.id => 1 }, unassign: { user1.id => 1, user3.id => 1 } } }

        it_behaves_like 'a service that can create a merge request'
        it_behaves_like 'a service that can change assignees of a merge request', 1
      end
    end

    context 'with an existing branch that has a merge request open' do
      let(:changes) { existing_branch_changes }
      let!(:merge_request) { create(:merge_request, source_project: project, source_branch: source_branch)}

      it_behaves_like 'a service that does not create a merge request'
      it_behaves_like 'a service that can change assignees of a merge request', 1
    end
  end
end
