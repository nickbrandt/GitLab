# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::BaseService do
  include ProjectForksHelper

  subject { MergeRequests::CreateService.new(project, project.owner, params) }

  let(:project) { create(:project, :repository) }
  let(:params_filtering_service) { double(:params_filtering_service) }
  let(:params) do
    {
      title: 'Awesome merge_request',
      description: 'please fix',
      source_branch: 'feature',
      target_branch: 'master'
    }
  end

  describe '#filter_params' do
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

  describe '#create_pipeline_for' do
    subject { service.execute }

    let(:service) { MergeRequests::CreateService.new(source_project, user, opts) }
    let(:user) { create(:user) }
    let(:title) { 'Awesome merge request' }
    let(:merge_pipelines_enabled) { true }
    let(:merge_pipelines_license) { true }
    let(:source_project) { project }
    let(:source_branch) { 'feature' }
    let(:target_project) { project }
    let(:target_branch) { 'master' }

    let(:opts) do
      {
        title: title,
        description: 'A new fix',
        source_branch: source_branch,
        source_project: source_project,
        target_branch: target_branch,
        target_project: target_project
      }
    end

    let(:ci_yaml) do
      {
        test: {
          stage: 'test',
          script: 'echo',
          only: ['merge_requests']
        }
      }
    end

    before do
      source_project.add_developer(user)
      target_project.add_developer(user)
      source_project.merge_pipelines_enabled = merge_pipelines_enabled
      stub_licensed_features(merge_pipelines: merge_pipelines_license)
      stub_ci_pipeline_yaml_file(YAML.dump(ci_yaml))
    end

    shared_examples_for 'creates a merge requst pipeline' do
      it do
        expect(subject).to be_persisted
        expect(subject.all_pipelines.count).to eq(1)
        expect(subject.all_pipelines.last).to be_merge_request_pipeline
        expect(subject.all_pipelines.last).not_to be_detached_merge_request_pipeline
      end
    end

    shared_examples_for 'creates a detached merge requst pipeline' do
      it do
        expect(subject).to be_persisted
        expect(subject.all_pipelines.count).to eq(1)
        expect(subject.all_pipelines.last).not_to be_merge_request_pipeline
        expect(subject.all_pipelines.last).to be_detached_merge_request_pipeline
      end
    end

    it_behaves_like 'creates a merge requst pipeline'

    context 'when merge request is WIP' do
      let(:title) { 'WIP: Awesome merge request' }

      it_behaves_like 'creates a detached merge requst pipeline'
    end

    context 'when project setting for merge request pipelines is disabled' do
      let(:merge_pipelines_enabled) { false }

      it_behaves_like 'creates a detached merge requst pipeline'
    end

    context 'when ci_use_merge_request_ref feature flag is disabled' do
      before do
        stub_feature_flags(ci_use_merge_request_ref: false)
      end

      it_behaves_like 'creates a detached merge requst pipeline'
    end

    context 'when merge request is submitted from fork' do
      let(:source_project) { fork_project(project, nil, repository: true) }

      it_behaves_like 'creates a detached merge requst pipeline'
    end

    context 'when the CreateService is retried' do
      it 'does not create a merge request pipeline twice' do
        expect do
          2.times { MergeRequests::CreateService.new(source_project, user, opts).execute }
        end.to change { Ci::Pipeline.count }.by(1)
      end
    end

    context 'when merge request has no commit' do
      let(:source_branch) { 'empty-branch' }

      it_behaves_like 'creates a detached merge requst pipeline'
    end

    context 'when merge request has a conflict' do
      let(:source_branch) { 'feature' }
      let(:target_branch) { 'feature_conflict' }

      it_behaves_like 'creates a detached merge requst pipeline'
    end
  end
end
