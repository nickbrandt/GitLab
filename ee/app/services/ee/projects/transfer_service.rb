# frozen_string_literal: true

module EE
  module Projects
    module TransferService
      extend ::Gitlab::Utils::Override

      private

      override :execute_system_hooks
      def execute_system_hooks
        super

        EE::Audit::ProjectChangesAuditor.new(current_user, project).execute

        ::Geo::RepositoryRenamedEventStore.new(
          project,
          old_path: project.path,
          old_path_with_namespace: old_path
        ).create!
      end

      override :transfer
      def transfer(project)
        if project.feature_available?(:packages) && project.has_packages?(:npm) && !new_namespace_has_same_root?(project)
          raise ::Projects::TransferService::TransferError.new(s_("TransferProject|Root namespace can't be updated if project has NPM packages"))
        end

        super
      end

      def new_namespace_has_same_root?(project)
        new_namespace.root_ancestor == project.namespace.root_ancestor
      end
    end
  end
end
