# frozen_string_literal: true

module EE
  module Types
    module MutationType
      extend ActiveSupport::Concern

      prepended do
        mount_mutation ::Mutations::Issues::SetIteration
        mount_mutation ::Mutations::Issues::SetWeight
        mount_mutation ::Mutations::EpicTree::Reorder
        mount_mutation ::Mutations::Epics::Update
        mount_mutation ::Mutations::Epics::Create
        mount_mutation ::Mutations::Epics::SetSubscription
        mount_mutation ::Mutations::Epics::AddIssue
        mount_mutation ::Mutations::Iterations::Create
        mount_mutation ::Mutations::RequirementsManagement::CreateRequirement
        mount_mutation ::Mutations::RequirementsManagement::UpdateRequirement
        mount_mutation ::Mutations::Vulnerabilities::Dismiss
        mount_mutation ::Mutations::Boards::Lists::UpdateLimitMetrics
        mount_mutation ::Mutations::InstanceSecurityDashboard::AddProject
        mount_mutation ::Mutations::InstanceSecurityDashboard::RemoveProject
        mount_mutation ::Mutations::Pipelines::RunDastScan
      end
    end
  end
end
