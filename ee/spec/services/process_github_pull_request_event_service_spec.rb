# frozen_string_literal: true

require 'spec_helper'

describe ProcessGithubPullRequestEventService do
  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }
  let(:action) { 'opened' }
  let(:params) do
    {
      pull_request: {
        id: 123,
        head: {
          ref: source_branch,
          sha: source_sha,
          repo: { full_name: 'the-repo' }
        },
        base: {
          ref: 'the-target-branch',
          sha: 'a09386439ca39abe575675ffd4b89ae824fec22f',
          repo: { full_name: 'the-repo' }
        }
      },
      action: action
    }
  end

  subject { described_class.new(project, user) }

  describe '#execute' do
    context 'when project is not a mirror' do
      let(:source_branch) { double }
      let(:source_sha) { double }

      it 'does nothing' do
        expect(subject.execute(params)).to be_nil
      end
    end

    context 'when project is a mirror' do
      before do
        allow(project).to receive(:mirror?).and_return(true)
      end

      context 'when mirror update occurs before the pull request webhook' do
        let(:branch) { project.repository.branches.first }
        let(:source_branch) { branch.name }
        let(:source_sha) { branch.target }

        let(:create_pipeline_service) { instance_double(Ci::CreatePipelineService) }

        it 'creates a pipeline and saves pull request info' do
          pipeline_params = {
            ref: Gitlab::Git::BRANCH_REF_PREFIX + branch.name,
            source_sha: branch.target,
            target_sha: 'a09386439ca39abe575675ffd4b89ae824fec22f'
          }
          expect(Ci::CreatePipelineService).to receive(:new)
            .with(project, user, pipeline_params)
            .and_return(create_pipeline_service)
          expect(create_pipeline_service).to receive(:execute)
            .with(:external_pull_request_event, any_args)

          expect { subject.execute(params) }.to change { ExternalPullRequest.count }.by(1)
        end
      end

      context 'when the pull request webhook occurs before mirror update' do
        let(:source_branch) { 'a-new-branch' }
        let(:source_sha) { 'non-existent-sha' }

        it 'only saves pull request info' do
          expect(Ci::CreatePipelineService).not_to receive(:new)

          expect { subject.execute(params) }.to change { ExternalPullRequest.count }.by(1)

          pull_request = ExternalPullRequest.last

          expect(pull_request).to be_persisted
          expect(pull_request.project).to eq(project)
          expect(pull_request.source_branch).to eq('a-new-branch')
          expect(pull_request.source_repository).to eq('the-repo')
          expect(pull_request.target_branch).to eq('the-target-branch')
          expect(pull_request.target_repository).to eq('the-repo')
          expect(pull_request.status).to eq('open')
        end
      end

      context 'when pull request webhook action is "closed"' do
        let(:source_branch) { 'a-new-branch' }
        let(:source_sha) { 'non-existent-sha' }
        let(:action) { 'closed' }

        it 'only saves pull request info' do
          expect(Ci::CreatePipelineService).not_to receive(:new)

          expect { subject.execute(params) }.to change { ExternalPullRequest.count }.by(1)

          pull_request = ExternalPullRequest.last

          expect(pull_request).to be_persisted
          expect(pull_request.project).to eq(project)
          expect(pull_request.source_branch).to eq('a-new-branch')
          expect(pull_request.source_repository).to eq('the-repo')
          expect(pull_request.target_branch).to eq('the-target-branch')
          expect(pull_request.target_repository).to eq('the-repo')
          expect(pull_request.status).to eq('closed')
        end
      end

      context 'when pull request webhook has unsupported action' do
        let(:source_branch) { double }
        let(:source_sha) { double }
        let(:action) { 'assigned' }

        it 'returns nil' do
          expect(subject.execute(params)).to be_nil
        end
      end

      context 'project is not a mirror' do
        let(:source_branch) { double }
        let(:source_sha) { double }

        before do
          allow(project).to receive(:mirror?).and_return(false)
        end

        it 'returns nil' do
          expect(subject.execute(params)).to be_nil
        end
      end

      context 'when pull request webhook any missing params' do
        let(:source_branch) { nil }
        let(:source_sha) { nil }

        it 'returns a pull request with errors' do
          expect(subject.execute(params).errors).not_to be_empty
        end
      end
    end
  end
end
