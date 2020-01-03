# frozen_string_literal: true

require 'spec_helper'

describe Boards::ListService do
  shared_examples 'boards list service' do
    let(:service) { described_class.new(resource_parent, double) }
    let!(:boards) { create_list(:board, 3, resource_parent: resource_parent) }

    describe '#execute' do
      it 'returns all issue boards when multiple issue boards is enabled' do
        stub_licensed_features(multiple_group_issue_boards: true)

        expect(service.execute.size).to eq(3)
      end

      it 'returns boards ordered by name' do
        board_names = %w[a-board B-board c-board].shuffle
        boards.each_with_index { |board, i| board.update_column(:name, board_names[i]) }
        stub_licensed_features(multiple_group_issue_boards: true)

        expect(service.execute.pluck(:name)).to eq(%w[a-board B-board c-board])
      end
    end
  end

  it_behaves_like 'boards list service' do
    let(:resource_parent) { create(:project, :empty_repo) }
  end

  it_behaves_like 'boards list service' do
    let(:resource_parent) { create(:group) }

    it 'returns the first issue board when multiple issue boards is disabled' do
      stub_licensed_features(multiple_group_issue_boards: false)

      expect(service.execute.size).to eq(1)
    end
  end
end
