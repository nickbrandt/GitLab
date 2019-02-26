# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::MergeToRefService do
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

      it 'returns the correct error message' do
        result = service.execute(merge_request)

        expected_error =
          'This merge request cannot be merged, because this repository ' \
          'has exceeded its size limit'

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to start_with(expected_error)
      end
    end
  end

  it_behaves_like 'merge validation hooks', persisted: false
end
