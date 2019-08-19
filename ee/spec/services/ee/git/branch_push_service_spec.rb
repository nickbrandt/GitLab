require 'spec_helper'

describe Git::BranchPushService do
  include RepoHelpers

  set(:user)     { create(:user) }
  let(:blankrev) { Gitlab::Git::BLANK_SHA }
  let(:oldrev)   { sample_commit.parent_id }
  let(:newrev)   { sample_commit.id }
  let(:ref)      { 'refs/heads/master' }

  subject do
    described_class.new(project, user, oldrev: oldrev, newrev: newrev, ref: ref)
  end

  context 'with pull project' do
    set(:project) { create(:project, :repository, :mirror) }

    before do
      allow(project.repository).to receive(:commit).and_call_original
      allow(project.repository).to receive(:commit).with("master").and_return(nil)
    end

    context 'deleted branch' do
      let(:newrev) { blankrev }

      it 'handles when remote branch exists' do
        expect(project.repository).to receive(:commit).with("refs/remotes/upstream/master").and_return(sample_commit)

        subject.execute
      end
    end

    context 'ElasticSearch indexing', :elastic do
      before do
        stub_ee_application_setting(elasticsearch_indexing?: true)
      end

      context 'when the project is locked by elastic.rake', :clean_gitlab_redis_shared_state do
        before do
          Gitlab::Redis::SharedState.with { |redis| redis.sadd(:elastic_projects_indexing, project.id) }
        end

        it 'does not run ElasticCommitIndexerWorker' do
          expect(ElasticCommitIndexerWorker).not_to receive(:perform_async)

          subject.execute
        end
      end

      it 'runs ElasticCommitIndexerWorker' do
        expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id, oldrev, newrev)

        subject.execute
      end

      it "does not trigger indexer when push to non-default branch" do
        expect_any_instance_of(Gitlab::Elastic::Indexer).not_to receive(:run)

        execute_service(project, user, oldrev, newrev, 'refs/heads/other')
      end

      it "triggers indexer when push to default branch" do
        expect_any_instance_of(Gitlab::Elastic::Indexer).to receive(:run)

        execute_service(project, user, oldrev, newrev, ref)
      end

      context 'when limited indexing is on' do
        before do
          stub_ee_application_setting(elasticsearch_limit_indexing: true)
        end

        context 'when the project is not enabled specifically' do
          it 'does not run ElasticCommitIndexerWorker' do
            expect(ElasticCommitIndexerWorker).not_to receive(:perform_async)

            subject.execute
          end
        end

        context 'when a project is enabled specifically' do
          before do
            create :elasticsearch_indexed_project, project: project
          end

          it 'runs ElasticCommitIndexerWorker' do
            expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id, oldrev, newrev)

            subject.execute
          end
        end

        context 'when a group is enabled' do
          let(:group) { create(:group) }
          let(:project) { create(:project, :repository, :mirror, group: group) }

          before do
            create :elasticsearch_indexed_namespace, namespace: group
          end

          it 'runs ElasticCommitIndexerWorker' do
            expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id, oldrev, newrev)

            subject.execute
          end
        end
      end
    end
  end

  context 'Jira Connect hooks' do
    set(:project) { create(:project, :repository) }

    shared_examples 'enqueues Jira sync worker' do
      it do
        Sidekiq::Testing.fake! do
          expect { subject.execute }.to change(JiraConnect::SyncBranchWorker.jobs, :size).by(1)
        end
      end
    end

    shared_examples 'does not enqueue Jira sync worker' do
      it do
        Sidekiq::Testing.fake! do
          expect { subject.execute }.not_to change(JiraConnect::SyncBranchWorker.jobs, :size)
        end
      end
    end

    context 'when feature is enabled' do
      before do
        stub_feature_flags(jira_connect_app: true)
      end

      context 'has Jira dev panel integration license' do
        before do
          stub_licensed_features(jira_dev_panel_integration: true)
        end

        context 'with a Jira subscription' do
          before do
            create(:jira_connect_subscription, namespace: project.namespace)
          end

          context 'branch name contains Jira issue key' do
            let(:ref) { 'refs/heads/branch-JIRA-123' }

            it_behaves_like 'enqueues Jira sync worker'
          end

          context 'commit message contains Jira issue key' do
            before do
              allow_any_instance_of(Commit).to receive(:safe_message).and_return('Commit with key JIRA-123')
            end

            it_behaves_like 'enqueues Jira sync worker'
          end

          context 'branch name and commit message does not contain Jira issue key' do
            it_behaves_like 'does not enqueue Jira sync worker'
          end
        end

        context 'without a Jira subscription' do
          it_behaves_like 'does not enqueue Jira sync worker'
        end
      end

      context 'does not have Jira dev panel integration license' do
        before do
          stub_licensed_features(jira_dev_panel_integration: false)
        end

        it_behaves_like 'does not enqueue Jira sync worker'
      end
    end

    context 'when feature is disabled' do
      before do
        stub_feature_flags(jira_connect_app: false)
      end

      it_behaves_like 'does not enqueue Jira sync worker'
    end
  end

  def execute_service(project, user, oldrev, newrev, ref)
    service = described_class.new(project, user, oldrev: oldrev, newrev: newrev, ref: ref)
    service.execute
    service
  end
end
