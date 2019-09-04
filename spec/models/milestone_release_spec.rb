# frozen_string_literal: true

require 'spec_helper'

describe MilestoneRelease do
  let(:project) { create(:project) }
  let(:release) { create(:release, project: project) }
  let(:milestone) { create(:milestone, project: project) }

  subject { build(:milestone_release, release: release, milestone: milestone) }

  describe 'associations' do
    it { is_expected.to belong_to(:milestone) }
    it { is_expected.to belong_to(:release) }
  end

  describe 'validations' do
    context 'when trying to create the same record in milestone_releases twice' do
      it 'is not committing on the second time' do
        described_class.create!(milestone_id: milestone.id, release_id: release.id)
        expect do
          described_class.create!(milestone_id: milestone.id, release_id: release.id)
        end.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context 'when milestone and release do not have the same project' do
      it 'is not valid' do
        other_project = create(:project)
        release = build(:release, project: other_project)
        milestone_release = described_class.new(milestone: milestone, release: release)
        expect(milestone_release).not_to be_valid
      end
    end

    context 'when milestone and release have the same project' do
      it 'is valid' do
        milestone_release = described_class.new(milestone: milestone, release: release)
        expect(milestone_release).to be_valid
      end
    end
  end
end
