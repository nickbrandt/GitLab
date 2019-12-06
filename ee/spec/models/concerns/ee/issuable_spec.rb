# frozen_string_literal: true

require 'spec_helper'

describe EE::Issuable do
  describe "Validation" do
    context 'general validations' do
      subject { build(:epic) }

      before do
        allow(InternalId).to receive(:generate_next).and_return(nil)
      end

      it { is_expected.to validate_presence_of(:iid) }
      it { is_expected.to validate_presence_of(:author) }
      it { is_expected.to validate_presence_of(:title) }
      it { is_expected.to validate_length_of(:title).is_at_most(::Issuable::TITLE_LENGTH_MAX) }
      it { is_expected.to validate_length_of(:description).is_at_most(::Issuable::DESCRIPTION_LENGTH_MAX).on(:create) }

      it_behaves_like 'validates description length with custom validation'
      it_behaves_like 'truncates the description to its allowed maximum length on import'
    end
  end

  describe '.labels_hash' do
    let(:feature_label) { create(:label, title: 'Feature') }
    let(:second_label) { create(:label, title: 'Second Label') }
    let!(:issues) { create_list(:labeled_issue, 3, labels: [feature_label, second_label]) }
    let(:issue_id) { issues.first.id }

    it 'maps issue ids to labels titles' do
      expect(Issue.labels_hash[issue_id]).to include('Feature')
    end

    it 'works on relations filtered by multiple labels' do
      relation = Issue.with_label(['Feature', 'Second Label'])

      expect(relation.labels_hash[issue_id]).to include('Feature', 'Second Label')
    end
  end

  describe '#matches_cross_reference_regex?' do
    context "epic description with long path string" do
      let(:mentionable) { build(:epic, description: "/a" * 50000) }

      it_behaves_like 'matches_cross_reference_regex? fails fast'
    end
  end
end
