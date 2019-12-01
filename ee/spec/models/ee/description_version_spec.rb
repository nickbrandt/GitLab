# frozen_string_literal: true

require 'spec_helper'

describe DescriptionVersion do
  describe 'associations' do
    it { is_expected.to belong_to :epic }
  end

  describe 'validations' do
    it 'is valid when epic_id is set' do
      expect(described_class.new(epic_id: 1)).to be_valid
    end
  end

  describe '#previous_version' do
    let(:issue) { create(:issue) }
    let(:previous_version) { create(:description_version, issue: issue) }
    let(:current_version) { create(:description_version, issue: issue) }

    before do
      create(:description_version, issue: issue)
      create(:description_version)

      previous_version
      current_version

      create(:description_version, issue: issue)
    end

    it 'returns the previous version for the same issuable' do
      expect(current_version.previous_version).to eq(previous_version)
    end
  end
end
