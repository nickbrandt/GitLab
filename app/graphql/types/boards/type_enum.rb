# frozen_string_literal: true

module Types
  module Boards
    class TypeEnum < BaseEnum
      graphql_name 'BoardTypeEnum'
      description 'The type of object the board can display'

      value 'ISSUE', description: "Issue board", value: 'issue'
      value 'EPIC', description: 'Epic board', value: 'epic'
    end
  end
end
