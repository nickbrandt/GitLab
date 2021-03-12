# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Board do
  let(:board) { create(:board) }

  it { is_expected.to include_module(EE::Board) }

  describe 'relationships' do
    it { is_expected.to belong_to(:milestone) }
    it { is_expected.to belong_to(:iteration) }
    it { is_expected.to have_one(:board_assignee) }
    it { is_expected.to have_one(:assignee).through(:board_assignee) }
    it { is_expected.to have_many(:board_labels) }
    it { is_expected.to have_many(:labels).through(:board_labels) }
    it { is_expected.to have_many(:user_preferences) }
    it { is_expected.to have_many(:boards_epic_user_preferences).class_name('Boards::EpicUserPreference') }
  end

  context 'validations' do
    context 'when group is present' do
      subject { described_class.new(group: create(:group)) }

      it { is_expected.not_to validate_presence_of(:project) }
      it { is_expected.to validate_presence_of(:group) }
    end

    context 'when project is present' do
      subject { described_class.new(project: create(:project)) }

      it { is_expected.to validate_presence_of(:project) }
      it { is_expected.not_to validate_presence_of(:group) }
    end
  end

  describe 'milestone' do
    context 'when the feature is available' do
      before do
        stub_licensed_features(scoped_issue_board: true)
      end

      it 'returns Milestone::None for started milestone id' do
        board.milestone_id = Milestone::None.id

        expect(board.milestone).to eq Milestone::None
      end

      it 'returns Milestone::Any for started milestone id' do
        board.milestone_id = Milestone::Any.id

        expect(board.milestone).to eq Milestone::Any
      end

      it 'returns Milestone::Upcoming for upcoming milestone id' do
        board.milestone_id = Milestone::Upcoming.id

        expect(board.milestone).to eq Milestone::Upcoming
      end

      it 'returns Milestone::Started for started milestone id' do
        board.milestone_id = Milestone::Started.id

        expect(board.milestone).to eq Milestone::Started
      end

      it 'returns milestone for valid milestone id' do
        milestone = create(:milestone)
        board.milestone_id = milestone.id

        expect(board.milestone).to eq milestone
      end
    end

    it 'returns nil when the feature is not available' do
      stub_licensed_features(scoped_issue_board: false)
      milestone = create(:milestone)
      board.milestone_id = milestone.id

      expect(board.milestone).to be_nil
    end
  end

  describe 'iteration' do
    let_it_be(:group) { create(:group) }

    it 'returns nil when the feature is not available' do
      stub_licensed_features(scoped_issue_board: false)
      iteration = create(:iteration, group: group)
      board.iteration_id = iteration.id

      expect(board.iteration).to be_nil
    end

    context 'when the feature is available' do
      before do
        stub_licensed_features(scoped_issue_board: true)
      end

      it 'returns Iteration::Predefined::None, when iteration_id is None.id' do
        board.iteration_id = Iteration::Predefined::None.id

        expect(board.iteration).to eq Iteration::Predefined::None
      end

      it 'returns Iteration::Predefined::Any, when iteration_id is Any.id' do
        board.iteration_id = Iteration::Predefined::Any.id

        expect(board.iteration).to eq Iteration::Predefined::Any
      end

      it 'returns ::Iteration::Predefined::Current, when iteration_id is Current.id' do
        board.iteration_id = Iteration::Predefined::Current.id

        expect(board.iteration).to eq Iteration::Predefined::Current
      end

      it 'returns iteration for valid iteration id' do
        iteration = create(:iteration)
        board.iteration_id = iteration.id

        expect(board.iteration).to eq iteration
      end

      it 'returns nil for invalid iteration id' do
        board.iteration_id = -2

        expect(board.iteration).to be_nil
      end
    end
  end

  describe '#scoped?' do
    before do
      stub_licensed_features(scoped_issue_board: true)
    end

    it 'returns true when milestone is not nil AND is not "Any milestone"' do
      milestone = create(:milestone)
      board = create(:board, milestone: milestone, weight: nil, labels: [], assignee: nil)

      expect(board).to be_scoped
    end

    it 'returns true when weight is not nil AND is not "Any weight"' do
      board = create(:board, milestone: nil, weight: 2, labels: [], assignee: nil)

      expect(board).to be_scoped
    end

    it 'returns true when any label exists' do
      board = create(:board, milestone: nil, weight: nil, assignee: nil)
      board.labels.create!(title: 'foo')

      expect(board).to be_scoped
    end

    it 'returns true when assignee is present' do
      user = create(:user)
      board = create(:board, milestone: nil, weight: nil, labels: [], assignee: user)

      expect(board).to be_scoped
    end

    it 'returns false when feature is not available' do
      stub_licensed_features(scoped_issue_board: false)

      expect(board).not_to be_scoped
    end

    it 'returns false when board is not scoped' do
      board = create(:board, milestone_id: -1, weight: -1, labels: [], assignee: nil)

      expect(board).not_to be_scoped
    end
  end
end
