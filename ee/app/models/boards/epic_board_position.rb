# frozen_string_literal: true

module Boards
  class EpicBoardPosition < ApplicationRecord
    include RelativePositioning

    self.table_name = 'boards_epic_board_positions'

    belongs_to :board
    belongs_to :epic

    validates :board, presence: true
    validates :epic, presence: true, uniqueness: { scope: :board_id }

    alias_attribute :parent, :board

    scope :order_relative_position, -> do
      reorder('relative_position ASC', 'id DESC')
    end

    def self.relative_positioning_query_base(position)
      where(board_id: position.board_id)
    end

    def self.relative_positioning_parent_column
      :board_id
    end
  end
end
