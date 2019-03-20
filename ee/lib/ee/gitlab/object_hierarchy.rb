# frozen_string_literal: true

module EE
  module Gitlab
    module ObjectHierarchy
      # rubocop: disable CodeReuse/ActiveRecord
      def roots
        base_and_ancestors.where(namespaces: { parent_id: nil })
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
