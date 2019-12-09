# frozen_string_literal: true

require 'spec_helper'

describe MergeRequestsComplianceFinder do
  subject { described_class.new(current_user, search_params) }

  let(:current_user) { create(:admin) }
  let(:search_params) { { group_id: group.id } }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }
  let(:project_2) { create(:project, namespace: group) }

  let(:mr_1) { create(:merge_request, source_project: project, state: :merged) }
  let(:mr_2) { create(:merge_request, source_project: project_2, state: :merged) }
  let(:mr_3) { create(:merge_request, source_project: project, source_branch: 'A', state: :merged) }
  let(:mr_4) { create(:merge_request, source_project: project_2, source_branch: 'A', state: :merged) }

  before do
    mr_1.metrics.update!(merged_at: 20.minutes.ago)
    mr_2.metrics.update!(merged_at: 40.minutes.ago)
    mr_3.metrics.update!(merged_at: 30.minutes.ago)
    mr_4.metrics.update!(merged_at: 50.minutes.ago)
  end

  context 'when there are merge requests from projects in group' do
    it 'shows only most recent Merge Request from each project' do
      expect(subject.execute).to contain_exactly(mr_1, mr_2)
    end

    it 'shows as many Merge Requests as they are projects with MR in group' do
      expect(subject.execute.size).to eq(group.projects.size)
    end

    context 'when there are merge requests from projects in group and subgroups' do
      let(:subgroup) { create(:group, parent: group) }
      let(:sub_project) { create(:project, namespace: subgroup) }

      let(:mr_5) { create(:merge_request, source_project: sub_project, state: :merged) }
      let(:mr_6) { create(:merge_request, source_project: sub_project, state: :merged) }

      before do
        mr_5.metrics.update!(merged_at: 10.minutes.ago)
        mr_6.metrics.update!(merged_at: 30.minutes.ago)
      end

      it 'shows only most recent Merge Request from each project' do
        expect(subject.execute).to contain_exactly(mr_1, mr_2, mr_5)
      end

      it 'shows Merge Requests from most recent to least recent' do
        expect(subject.execute).to eq([mr_5, mr_1, mr_2])
      end
    end
  end
end
