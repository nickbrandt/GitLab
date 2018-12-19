# frozen_string_literal: true

module EE
  module Projects
    module ImportsController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        include SafeMirrorParams
      end

      private

      override :import_params_attributes
      def import_params_attributes
        super + [:mirror, :mirror_user_id]
      end

      override :import_params
      def import_params
        base_import_params = super
        return base_import_params if valid_mirror_user?(base_import_params)

        base_import_params.merge(mirror_user_id: current_user.id)
      end
    end
  end
end
