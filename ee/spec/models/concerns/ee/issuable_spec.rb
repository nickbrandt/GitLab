# frozen_string_literal: true

require 'spec_helper'

describe EE::Issuable do
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

  describe '#milestone_available?' do
    context 'with Epic' do
      let(:epic) { create(:epic) }

      it 'returns true' do
        expect(epic.milestone_available?).to be_truthy
      end
    end

    context 'no Epic' do
      let(:issue) { create(:issue) }

      it 'returns false' do
        expect(issue.milestone_available?).to be_falsy
      end
    end
  end
end
