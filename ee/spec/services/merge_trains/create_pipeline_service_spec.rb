# frozen_string_literal: true

require 'spec_helper'

describe MergeTrains::CreatePipelineService do
  set(:project) { create(:project, :repository) }
  set(:maintainer) { create(:user) }
  let(:service) { described_class.new(project, maintainer) }

  before do
    project.add_maintainer(maintainer)
    stub_licensed_features(merge_pipelines: true, merge_trains: true)
    project.update!(merge_pipelines_enabled: true, merge_trains_enabled: true)
  end

  describe '#execute' do
    subject { service.execute(merge_request) }

    let!(:merge_request) do
      create(:merge_request, :on_train, train_creator: maintainer,
        source_branch: 'feature', source_project: project,
        target_branch: 'master', target_project: project,
        merge_status: 'unchecked')
    end

    shared_examples_for 'returns an error' do
      let(:expected_reason) { 'unknown' }

      it do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq(expected_reason)
      end
    end

    context 'when merge trains option is disabled' do
      before do
        project.update!(merge_trains_enabled: false)
      end

      it_behaves_like 'returns an error' do
        let(:expected_reason) { 'merge trains is disabled' }
      end

      after do
        project.update!(merge_trains_enabled: true)
      end
    end

    context 'when merge request is not on a merge train' do
      let!(:merge_request) do
        create(:merge_request,
          source_branch: 'feature', source_project: project,
          target_branch: 'master', target_project: project)
      end

      it_behaves_like 'returns an error' do
        let(:expected_reason) { 'merge request is not on a merge train' }
      end
    end

    context 'when merge request is submitted from a forked project' do
      before do
        allow(merge_request).to receive(:for_fork?) { true }
      end

      it_behaves_like 'returns an error' do
        let(:expected_reason) { 'fork merge request is not supported' }
      end
    end

    context 'when prepared merge ref successfully' do
      context 'when .gitlab-ci.yml has only: [merge_requests] specification' do
        let(:ci_yaml) do
          { test: { stage: 'test', script: 'echo', only: ['merge_requests'] } }
        end

        before do
          stub_ci_pipeline_yaml_file(YAML.dump(ci_yaml))
        end

        it 'creates train ref' do
          expect { subject }
            .to change { merge_request.project.repository.ref_exists?(merge_request.train_ref_path) }
            .from(false).to(true)
        end

        it 'calls Ci::CreatePipelineService for creating pipeline on train ref' do
          expect_next_instance_of(Ci::CreatePipelineService, project, maintainer, hash_including(ref: merge_request.train_ref_path)) do |pipeline_service|
            expect(pipeline_service).to receive(:execute)
              .with(:merge_request_event, hash_including(merge_request: merge_request)).and_call_original
          end

          subject
        end
      end

      context 'when .gitlab-ci.yml does not have only: [merge_requests] specification' do
        it_behaves_like 'returns an error' do
          let(:expected_reason) { 'No stages / jobs for this pipeline.' }
        end
      end
    end

    context 'when failed to prepare merge ref' do
      before do
        check_service = double
        allow(::MergeRequests::MergeToRefService).to receive(:new) { check_service }
        allow(check_service).to receive(:execute) { { status: :error, message: 'Merge ref was not found' } }
      end

      it_behaves_like 'returns an error' do
        let(:expected_reason) { 'Merge ref was not found' }
      end
    end
  end
end
