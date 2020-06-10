# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::BaseService do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :repository) }
  let(:title) { 'Awesome merge_request' }
  let(:params) do
    {
      title: title,
      description: 'please fix',
      source_branch: 'feature',
      target_branch: 'master'
    }
  end

  subject { MergeRequests::CreateService.new(project, project.owner, params) }

  describe '#execute_hooks' do
    shared_examples 'enqueues Jira sync worker' do
      it do
        Sidekiq::Testing.fake! do
          expect { subject.execute }.to change(JiraConnect::SyncMergeRequestWorker.jobs, :size).by(1)
        end
      end
    end

    shared_examples 'does not enqueue Jira sync worker' do
      it do
        Sidekiq::Testing.fake! do
          expect { subject.execute }.not_to change(JiraConnect::SyncMergeRequestWorker.jobs, :size)
        end
      end
    end

    context 'has Jira dev panel integration license' do
      before do
        stub_licensed_features(jira_dev_panel_integration: true)
      end

      context 'with a Jira subscription' do
        before do
          create(:jira_connect_subscription, namespace: project.namespace)
        end

        context 'MR contains Jira issue key' do
          let(:title) { 'Awesome merge_request with issue JIRA-123' }

          it_behaves_like 'enqueues Jira sync worker'
        end

        context 'MR does not contain Jira issue key' do
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

  describe '#filter_params' do
    let(:params_filtering_service) { double(:params_filtering_service) }

    context 'filter users and groups' do
      before do
        allow(subject).to receive(:execute_hooks)
      end

      it 'calls ParamsFilteringService' do
        expect(ApprovalRules::ParamsFilteringService).to receive(:new).with(
          an_instance_of(MergeRequest),
          project.owner,
          params
        ).and_return(params_filtering_service)
        expect(params_filtering_service).to receive(:execute).and_return(params)

        subject.execute
      end
    end
  end
end
