require 'spec_helper'

describe MergeRequestsFinder do
  it_behaves_like 'a finder with external authorization service' do
    let!(:subject) { create(:merge_request, source_project: project) }
    let(:project_params) { { project_id: project.id } }
  end

  describe '#execute' do
    include_context 'MergeRequestsFinder multiple projects with merge requests context'

    it 'ignores filtering by weight' do
      params = { project_id: project1.id, scope: 'authored', state: 'opened', weight: Issue::WEIGHT_ANY }

      merge_requests = described_class.new(user, params).execute

      expect(merge_requests).to contain_exactly(merge_request1)
    end
  end
end
