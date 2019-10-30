# frozen_string_literal: true

module EE
  module Types
    module MutationType
      extend ActiveSupport::Concern

      prepended do
        mount_mutation ::Mutations::DesignManagement::Upload, calls_gitaly: true
        mount_mutation ::Mutations::DesignManagement::Delete, calls_gitaly: true
        mount_mutation ::Mutations::EpicTree::Reorder
        mount_mutation ::Mutations::Epics::Update
        mount_mutation ::Mutations::Epics::Create
      end
    end
  end
end
