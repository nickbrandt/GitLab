# frozen_string_literal: true

require 'spec_helper'

describe BoardsResponses do
  let(:controller_class) do
    Class.new do
      include BoardsResponses
    end
  end

  subject(:controller) { controller_class.new }

  describe '#serialize_as_json' do
    let!(:board) { create(:board) }

    context 'with milestone' do
      let(:milestone) { create(:milestone) }

      before do
        board.update_attribute(:milestone_id, milestone.id)
      end

      it 'serialises properly' do
        # for ee
        # expected = { id: board.id, name: board.name, milestone: { id: milestone.id, title: milestone.name} }

        expected = { id: board.id }
        expect(subject.serialize_as_json(board)).to match(expected)
      end
    end

    context 'without milestone' do
      it 'serialises properly' do
        # for ee
        # expected = { id: board.id, name: board.name }
        #
        expected = { id: board.id }

        expect(subject.serialize_as_json(board)).to eq(expected)
      end
    end
  end
end
