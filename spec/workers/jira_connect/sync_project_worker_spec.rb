# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::SyncProjectWorker, factory_default: :keep do
  describe '#perform' do
    let_it_be(:project) { create_default(:project, :repository) }
    let!(:mr_with_jira_title) { create(:merge_request, :unique_branches, title: 'TEST-123') }
    let!(:mr_with_jira_description) { create(:merge_request, :unique_branches, description: 'TEST-323') }
    let!(:mr_with_other_title) { create(:merge_request, :unique_branches) }
    let!(:jira_subscription) { create(:jira_connect_subscription, namespace: project.namespace) }

    let(:jira_connect_sync_service) { JiraConnect::SyncService.new(project) }
    let(:job_args) { [project.id, update_sequence_id] }
    let(:update_sequence_id) { 1 }
    let(:jira_referencing_branch_name) { 'TEST-123_my-feature-branch' }

    before do
      stub_request(:post, 'https://sample.atlassian.net/rest/devinfo/0.10/bulk').to_return(status: 200, body: '', headers: {})

      jira_connect_sync_service
      allow(JiraConnect::SyncService).to receive(:new) { jira_connect_sync_service }

      project.repository.create_branch('my-feature-branch')
      project.repository.create_branch(jira_referencing_branch_name)
    end

    context 'when the project is not found' do
      it 'does not raise an error' do
        expect { described_class.new.perform('non_existing_record_id', update_sequence_id) }.not_to raise_error
      end
    end

    it 'avoids N+1 database queries' do
      control_count = ActiveRecord::QueryRecorder.new { described_class.new.perform(project.id, update_sequence_id) }.count

      create(:merge_request, :unique_branches, title: 'TEST-123')

      expect { described_class.new.perform(project.id, update_sequence_id) }.not_to exceed_query_limit(control_count)
    end

    context 'with multiple branches to sync' do
      after do
        project.repository.rm_branch(project.owner, 'TEST-2_my-feature-branch')
        project.repository.rm_branch(project.owner, 'TEST-3_my-feature-branch')
      end

      it 'avoids N+1 Gitaly requests', :request_store do
        initial_request_count = Gitlab::GitalyClient.get_request_count

        described_class.new.perform(project.id, update_sequence_id)

        control_count = Gitlab::GitalyClient.get_request_count - initial_request_count

        project.repository.create_branch('TEST-2_my-feature-branch')
        project.repository.create_branch('TEST-3_my-feature-branch')

        expect { described_class.new.perform(project.id, update_sequence_id) }
          .to change { Gitlab::GitalyClient.get_request_count }.by_at_most(control_count)
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:request_url) { 'https://sample.atlassian.net/rest/devinfo/0.10/bulk' }
      let(:request_body) do
        {
          repositories: [
            Atlassian::JiraConnect::Serializers::RepositoryEntity.represent(
              project,
              merge_requests: [mr_with_jira_description, mr_with_jira_title],
              branches: [project.repository.find_branch(jira_referencing_branch_name)],
              update_sequence_id: update_sequence_id
            )
          ]
        }.to_json
      end

      it 'sends the request with custom update_sequence_id' do
        expect(Atlassian::JiraConnect::Client).to receive(:post)
          .exactly(IdempotentWorkerHelper::WORKER_EXEC_TIMES).times
          .with(URI(request_url), headers: anything, body: request_body)

        subject
      end

      context 'when the number of merge requests to sync is higher than the limit' do
        let!(:most_recent_merge_request) { create(:merge_request, :unique_branches, description: 'TEST-323', title: 'TEST-123') }

        before do
          stub_const("#{described_class}::MAX_RECORDS_LIMIT", 1)

          project.repository.create_branch('TEST-321_new-branch')
        end

        it 'syncs only the most recent merge requests within the limit and limits the number of branches' do
          expect(jira_connect_sync_service).to receive(:execute)
            .exactly(IdempotentWorkerHelper::WORKER_EXEC_TIMES).times
            .with(merge_requests: [most_recent_merge_request], branches: [kind_of(Gitlab::Git::Branch)], update_sequence_id: update_sequence_id)

          subject
        end
      end
    end
  end
end
