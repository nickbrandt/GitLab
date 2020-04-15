# frozen_string_literal: true

module Gitlab
  module Pagination
    module Keyset
      def self.available_for_type?(relation)
        relation.klass == Project
      end

      def self.available?(request_context, relation)
        order_by = request_context.page.order_by

        return false unless available_for_type?(relation)
        return false unless order_by.size == 1 && order_by[:id]

        true
      end
    end
  end
end
