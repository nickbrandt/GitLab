# frozen_string_literal: true

module EE
  module Types
    module TodoTargetEnum
      extend ActiveSupport::Concern

      prepended do
        value 'DESIGN', value: 'DesignManagement::Design', description: 'A Design'
        value 'EPIC', value: 'Epic', description: 'An Epic'
      end
    end
  end
end
