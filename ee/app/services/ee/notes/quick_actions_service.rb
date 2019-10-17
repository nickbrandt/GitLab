# frozen_string_literal: true

module EE
  module Notes
    module QuickActionsService
      extend ActiveSupport::Concern
      include ::Gitlab::Utils::StrongMemoize

      prepended do
        EE_UPDATE_SERVICES = const_get(:UPDATE_SERVICES, false).merge(
          'Epic' => Epics::UpdateService
        ).freeze
        EE::Notes::QuickActionsService.private_constant :EE_UPDATE_SERVICES
      end

      class_methods do
        extend ::Gitlab::Utils::Override

        override :update_services
        def update_services
          EE_UPDATE_SERVICES
        end
      end
    end
  end
end
