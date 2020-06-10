# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EpicIssue do
  describe 'validations' do
    let(:epic) { build(:epic) }
    let(:confidential_epic) { build(:epic, :confidential) }
    let(:issue) { build(:issue) }
    let(:confidential_issue) { build(:issue, :confidential) }

    it 'is valid to add not-confidential issue to not-confidential epic' do
      expect(build(:epic_issue, epic: epic, issue: issue)).to be_valid
    end

    it 'is valid to add confidential issue to confidential epic' do
      expect(build(:epic_issue, epic: confidential_epic, issue: confidential_issue)).to be_valid
    end

    it 'is valid to add confidential issue to not-confidential epic' do
      expect(build(:epic_issue, epic: epic, issue: confidential_issue)).to be_valid
    end

    it 'is not valid to add not-confidential issue to confidential epic' do
      expect(build(:epic_issue, epic: confidential_epic, issue: issue)).not_to be_valid
    end
  end

  context "relative positioning" do
    it_behaves_like "a class that supports relative positioning" do
      let(:epic) { create(:epic) }
      let(:factory) { :epic_issue }
      let(:default_params) { { epic: epic } }
    end
  end
end
