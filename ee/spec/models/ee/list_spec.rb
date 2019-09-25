# frozen_string_literal: true

require 'spec_helper'

describe List do
  let(:board) { create(:board) }

  describe 'relationships' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:milestone) }
  end

  describe 'validations' do
    it { is_expected.to validate_numericality_of(:max_issue_count).only_integer.is_greater_than_or_equal_to(0) }
  end

  context 'when it is an assignee type' do
    subject { described_class.new(list_type: :assignee, board: board) }

    it { is_expected.to be_destroyable }
    it { is_expected.to be_movable }

    describe 'validations' do
      it { is_expected.to validate_presence_of(:user) }
    end

    describe '#title' do
      it 'returns the username as title' do
        subject.user = create(:user, username: 'some_user')

        expect(subject.title).to eq('@some_user')
      end
    end
  end

  context 'when it is a milestone type' do
    let(:milestone) { build(:milestone, title: 'awesome-release') }
    subject { described_class.new(list_type: :milestone, milestone: milestone, board: board) }

    it { is_expected.to be_destroyable }
    it { is_expected.to be_movable }

    describe 'validations' do
      it { is_expected.to validate_presence_of(:milestone) }

      it 'is invalid when feature is not available' do
        stub_licensed_features(board_milestone_lists: false)

        expect(subject).to be_invalid
        expect(subject.errors[:list_type])
          .to contain_exactly('Milestone lists not available with your current license')
      end
    end

    describe '#title' do
      it 'returns the milestone title' do
        expect(subject.title).to eq('awesome-release')
      end
    end
  end
end
