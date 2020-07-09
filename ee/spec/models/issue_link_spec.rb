# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueLink do
  describe 'Associations' do
    it { is_expected.to belong_to(:source).class_name('Issue') }
    it { is_expected.to belong_to(:target).class_name('Issue') }
  end

  describe 'link_type' do
    it { is_expected.to define_enum_for(:link_type).with_values(relates_to: 0, blocks: 1, is_blocked_by: 2) }

    it 'provides the "related" as default link_type' do
      expect(create(:issue_link).link_type).to eq 'relates_to'
    end
  end

  describe 'Validation' do
    subject { create :issue_link }

    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:target) }
    it do
      is_expected.to validate_uniqueness_of(:source)
        .scoped_to(:target_id)
        .with_message(/already related/)
    end

    context 'self relation' do
      let(:issue) { create :issue }

      context 'cannot be validated' do
        it 'does not invalidate object with self relation error' do
          issue_link = build :issue_link, source: issue, target: nil

          issue_link.valid?

          expect(issue_link.errors[:source]).to be_empty
        end
      end

      context 'can be invalidated' do
        it 'invalidates object' do
          issue_link = build :issue_link, source: issue, target: issue

          expect(issue_link).to be_invalid
          expect(issue_link.errors[:source]).to include('cannot be related to itself')
        end
      end
    end
  end

  describe '.blocked_issue_ids' do
    it 'returns only ids of issues which are blocked' do
      link1 = create(:issue_link, link_type: described_class::TYPE_BLOCKS)
      link2 = create(:issue_link, link_type: described_class::TYPE_IS_BLOCKED_BY)
      link3 = create(:issue_link, link_type: described_class::TYPE_RELATES_TO)
      link4 = create(:issue_link, source: create(:issue, :closed), link_type: described_class::TYPE_BLOCKS)

      expect(described_class.blocked_issue_ids([link1.target_id, link2.source_id, link3.source_id, link4.target_id]))
        .to match_array([link1.target_id, link2.source_id])
    end
  end

  describe '.blocking_issue_ids_for' do
    it 'returns blocking issue ids' do
      issue = create(:issue)
      blocking_issue = create(:issue, project: issue.project)
      blocked_by_issue = create(:issue, project: issue.project)
      create(:issue_link, source: blocking_issue, target: issue, link_type: IssueLink::TYPE_BLOCKS)
      create(:issue_link, source: issue, target: blocked_by_issue, link_type: IssueLink::TYPE_IS_BLOCKED_BY)

      blocking_ids = described_class.blocking_issue_ids_for(issue)

      expect(blocking_ids).to match_array([blocking_issue.id, blocked_by_issue.id])
    end
  end

  describe '.inverse_link_type' do
    it 'returns reverse type of link' do
      expect(described_class.inverse_link_type('relates_to')).to eq 'relates_to'
      expect(described_class.inverse_link_type('blocks')).to eq 'is_blocked_by'
      expect(described_class.inverse_link_type('is_blocked_by')).to eq 'blocks'
    end
  end

  describe 'collections' do
    let_it_be(:blocked_issue_1) { create(:issue) }
    let_it_be(:project) { blocked_issue_1.project }
    let_it_be(:blocked_issue_2) { create(:issue, project: project) }
    let_it_be(:blocked_issue_3) { create(:issue, project: project) }
    let_it_be(:blocking_issue_1) { create(:issue, project: project) }
    let_it_be(:blocking_issue_2) { create(:issue, project: project) }

    before :all do
      create(:issue_link, source: blocking_issue_1, target: blocked_issue_1, link_type: IssueLink::TYPE_BLOCKS)
      create(:issue_link, source: blocked_issue_2, target: blocking_issue_1, link_type: IssueLink::TYPE_IS_BLOCKED_BY)
      create(:issue_link, source: blocking_issue_2, target: blocked_issue_3, link_type: IssueLink::TYPE_BLOCKS)
    end

    describe '.blocking_issues_for_collection' do
      it 'returns blocking issues count grouped by issue id' do
        results = described_class.blocking_issues_for_collection([blocking_issue_1, blocking_issue_2])

        expect(results.find { |link| link.blocking_issue_id == blocking_issue_1.id }.count).to eq(2)
        expect(results.find { |link| link.blocking_issue_id == blocking_issue_2.id }.count).to eq(1)
      end
    end

    describe '.blocked_issues_for_collection' do
      it 'returns blocked issues count grouped by issue id' do
        results = described_class.blocked_issues_for_collection([blocked_issue_1, blocked_issue_2, blocked_issue_3])

        expect(result_by(results, blocked_issue_1.id).count).to eq(1)
        expect(result_by(results, blocked_issue_2.id).count).to eq(1)
        expect(result_by(results, blocked_issue_3.id).count).to eq(1)
      end
    end
  end

  def result_by(results, id)
    results.find { |link| link.blocked_issue_id == id }
  end
end
