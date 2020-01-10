# frozen_string_literal: true

shared_examples 'boards list service' do
  context 'when parent does not have a board' do
    it 'creates a new parent board' do
      expect { service.execute }.to change(parent.boards, :count).by(1)
    end

    it 'delegates the parent board creation to Boards::CreateService' do
      expect_any_instance_of(Boards::CreateService).to receive(:execute).once

      service.execute
    end
  end

  context 'when parent has a board' do
    before do
      create(:board, resource_parent: parent)
    end

    it 'does not create a new board' do
      expect { service.execute }.not_to change(parent.boards, :count)
    end
  end

  it 'returns parent boards' do
    board = create(:board, resource_parent: parent)

    expect(service.execute).to eq [board]
  end
end

shared_examples 'multiple boards list service' do
  let(:service) { described_class.new(parent, double) }
  let!(:boards) { create_list(:board, 3, resource_parent: parent) }

  describe '#execute' do
    it 'returns all issue boards' do
      expect(service.execute.size).to eq(3)
    end

    it 'returns boards ordered by name' do
      board_names = %w[B-board c-board a-board]
      boards.each_with_index { |board, i| board.update_column(:name, board_names[i]) }

      expect(service.execute.pluck(:name)).to eq(%w[a-board B-board c-board])
    end
  end
end
