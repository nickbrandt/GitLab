# frozen_string_literal: true

module EE
  module Gitlab
    module ImportExport
      module RelationFactory
        extend ActiveSupport::Concern

        EE_OVERRIDES = {
          design: 'DesignManagement::Design',
          designs: 'DesignManagement::Design',
          design_versions: 'DesignManagement::Version',
          actions: 'DesignManagement::Action',
          deploy_access_levels: 'ProtectedEnvironment::DeployAccessLevel',
          unprotect_access_levels: 'ProtectedBranch::UnprotectAccessLevel'
        }.freeze

        EE_EXISTING_OBJECT_CHECK = %i[DesignManagement::Design].freeze

        class_methods do
          extend ::Gitlab::Utils::Override

          override :overrides
          def overrides
            super.merge(EE_OVERRIDES)
          end

          override :existing_object_check
          def existing_object_check
            super + EE_EXISTING_OBJECT_CHECK
          end
        end
      end
    end
  end
end
