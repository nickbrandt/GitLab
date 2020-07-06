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

      override :permitted_attrs
      def permitted_attrs(type)
        return super unless type == 'issue'

        super.push(:health_status, :epic_id)
      end

      override :set_update_params
      def set_update_params(type)
        super

        set_health_status
      end

      def set_health_status
        return unless params[:health_status].present?

        params[:health_status] = nil if params[:health_status] == IssuableFinder::Params::NONE.to_s
      end
    end
  end
end
