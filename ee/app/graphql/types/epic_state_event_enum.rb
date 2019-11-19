# frozen_string_literal: true

module Types
  class EpicStateEventEnum < BaseEnum
    graphql_name 'EpicStateEvent'
    description 'State event of a GitLab Epic'

    value 'REOPEN', value: 'reopen', description: 'Reopen the Epic'
    value 'CLOSE', value: 'close', description: 'Close the Epic'
  end
end
