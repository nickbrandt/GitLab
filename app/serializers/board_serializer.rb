# frozen_string_literal: true

class BoardSerializer < BaseSerializer
  def represent(board, opts = {})
    entity =
      case opts[:serializer]
      when 'ee-board'
        EE::API::Entities::BoardSimple
      else
        ::API::Entities::BoardSimple
      end

    super(board, opts, entity)
  end
end
