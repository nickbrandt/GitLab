# frozen_string_literal: true

module EE
  module Gitlab
    module ImportExport
      module ProjectTreeRestorer
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        private

        override :remove_feature_dependent_sub_relations!
        def remove_feature_dependent_sub_relations!(relation_item)
          export_designs_disabled = ::Feature.disabled?(:export_designs, project, default_enabled: true)

          if relation_item.is_a?(Hash) && export_designs_disabled
            relation_item.except!('designs', 'design_versions')
          end
        end
      end
    end
  end
end
