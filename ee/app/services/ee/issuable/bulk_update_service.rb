# frozen_string_literal: true

module EE
  module Issuable
    module BulkUpdateService
      extend ::Gitlab::Utils::Override

      private

      # rubocop: disable CodeReuse/ActiveRecord
      override :find_issuables
      def find_issuables(model_class, ids, parent)
        if model_class.method_defined?("group") && parent.is_a?(Group)
          model_class.where(id: ids).where(group_id: parent.self_and_descendants)
        else
          super
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end

Issuable::BulkUpdateService.prepend_if_ee('EE::Issuable::BulkUpdateService')
