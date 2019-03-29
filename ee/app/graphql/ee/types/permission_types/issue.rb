# frozen_string_literal: true

module EE
  module Types
    module PermissionTypes
      module Issue
        extend ActiveSupport::Concern

        prepended do
          abilities :read_design, :create_design, :destroy_design
        end
      end
    end
  end
end
