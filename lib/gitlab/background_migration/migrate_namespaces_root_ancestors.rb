# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Class that will populate root_ancestor_id for each namespace in namespaces table
    class MigrateNamespacesRootAncestors
      # Temporary AR class for namespaces
      class ::Namespace < ApplicationRecord
        self.table_name = 'namespaces'

        def self_and_ancestors(hierarchy_order: nil)
          return self.class.where(id: id) unless parent_id

          Gitlab::ObjectHierarchy
            .new(self.class.where(id: id))
            .base_and_ancestors(hierarchy_order: hierarchy_order)
        end
      end

      def perform(start_id, stop_id)
        Namespace.where(id: start_id..stop_id).find_each do |namespace|
          namespace.update_column(:root_ancestor_id, namespace.self_and_ancestors.reorder(nil).find_by(parent_id: nil).id)
        end
      end
    end
  end
end
