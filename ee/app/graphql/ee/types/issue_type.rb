# frozen_string_literal: true

module EE
  module Types
    module IssueType
      extend ActiveSupport::Concern

      prepended do
        field :designs, ::Types::DesignManagement::DesignCollectionType,
              null: true, method: :design_collection
      end
    end
  end
end
