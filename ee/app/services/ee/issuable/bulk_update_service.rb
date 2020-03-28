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
    end
  end
end
