# frozen_string_literal: true

require 'spec_helper'

describe Analytics::GroupActivityCalculator do
  subject { described_class.new(group, current_user) }

  set(:group) { create(:group) }
  set(:current_user) { create(:user) }
  set(:subgroup) { create(:group, parent: group) }
  set(:project) { create(:project, group: subgroup) }
  set(:secret_subgroup) { create(:group, parent: group) }
  set(:secret_project) { create(:project, group: secret_subgroup) }

  before do
    subgroup.add_developer(current_user)
    project.add_developer(current_user)
  end

  context 'with issues' do
    set(:recent_issue) { create(:issue, project: project) }
    set(:old_issue) do
      create(:issue,
        project: project,
        created_at: 100.days.ago)
    end

    it 'only returns the count of recent issues' do
      expect(subject.issues_count).to eq 1
    end

    context 'when user does not have access to some issues' do
      let(:secret_issue) { create(:issue, project: secret_project) }

      it 'does not include those issues' do
        expect { secret_issue }.not_to change { subject.issues_count}
      end
    end
  end

  context 'with merge requests' do
    let!(:recent_mr) do
      create(:merge_request,
        source_project: project,
        source_branch: "my-personal-branch-1")
    end

    let!(:old_mr) do
      create(:merge_request,
        source_project: project,
        source_branch: "my-personal-branch-2",
        created_at: 100.days.ago)
    end

    it 'only returns the count of recent MRs' do
      expect(subject.merge_requests_count).to eq 1
    end

    context 'when user does not have access to some MRs' do
      let(:secret_mr) { create(:merge_request, source_project: secret_project) }

      it 'does not include those MRs' do
        expect { secret_mr }.not_to change { subject.merge_requests_count}
      end
    end
  end
end
