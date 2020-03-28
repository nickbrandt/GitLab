# frozen_string_literal: true

module EE
  module Types
    module BoardType
      extend ActiveSupport::Concern

      prepended do
        field :weight, type: GraphQL::INT_TYPE, null: true,
              description: 'Weight of the board'
      end
    end
  end
end
