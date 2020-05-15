# frozen_string_literal: true

module Types
  class IterationStateEventEnum < BaseEnum
    graphql_name 'IterationStateEvent'
    description 'State event of an iteration'

    value 'START', value: 'start', description: 'Force-starts the iteration'
    value 'CLOSE', value: 'close', description: 'Close the iteration'
  end
end
