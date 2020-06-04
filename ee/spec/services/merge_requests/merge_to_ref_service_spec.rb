# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::MergeToRefService do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, :simple) }
  let(:project) { merge_request.project }
  let(:service) { described_class.new(project, user, commit_message: 'Awesome message') }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    context 'project has exceeded size limit' do
      before do
        allow(project).to receive(:above_size_limit?).and_return(true)
      end

      it 'bypasses the repository limit check' do
        result = service.execute(merge_request)

        expect(result[:status]).to eq(:success)
      end
    end

    context 'when no commit message is explicitly given and push rule is set' do
      before do
        create(:push_rule, :commit_message, project: project)
      end

      let(:service) { described_class.new(project, user) }

      it 'uses the default commit message' do
        result = service.execute(merge_request)

        expect(result[:status]).to eq(:success)
        expect(project.commit(result[:commit_id]).message).to eq(merge_request.default_merge_commit_message)
      end
    end
  end

  it_behaves_like 'merge validation hooks', persisted: false
end
