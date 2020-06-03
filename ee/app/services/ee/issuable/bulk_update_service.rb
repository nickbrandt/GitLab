# frozen_string_literal: true

module EE
  module Issuable
    module BulkUpdateService
      extend ::Gitlab::Utils::Override

      private

      override :find_issuables
      def find_issuables(parent, model_class, ids)
        return model_class.for_ids(ids).in_selected_groups(parent.self_and_descendants) if model_class == ::Epic

        super
      end

      override :issuable_specific_attrs
      def issuable_specific_attrs(type, attrs)
        return super unless type == 'issue'

        super.push(:health_status, :epic)
      end
    end
  end
end
