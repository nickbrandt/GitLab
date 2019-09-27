# frozen_string_literal: true

module EE
  module Gitlab
    module ImportExport
      module ProjectTreeRestorer
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        private

        attr_accessor :project

        override :remove_feature_dependent_sub_relations
        def remove_feature_dependent_sub_relations(relation_item)
          if relation_item.is_a?(Hash) && ::Feature.disabled?(:export_designs, project, default_enabled: true)
            relation_item.except!('designs', 'design_versions')
          end
        end
      end
    end
  end
end
