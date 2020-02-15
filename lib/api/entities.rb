# frozen_string_literal: true

module API
  module Entities
  end
end

# rubocop: disable Cop/InjectEnterpriseEditionModule
::API::Entities::ApplicationSetting.prepend_if_ee('EE::API::Entities::ApplicationSetting')
::API::Entities::Board.prepend_if_ee('EE::API::Entities::Board')
::API::Entities::Group.prepend_if_ee('EE::API::Entities::Group', with_descendants: true)
::API::Entities::GroupDetail.prepend_if_ee('EE::API::Entities::GroupDetail')
::API::Entities::IssueBasic.prepend_if_ee('EE::API::Entities::IssueBasic', with_descendants: true)
::API::Entities::Issue.prepend_if_ee('EE::API::Entities::Issue')
::API::Entities::List.prepend_if_ee('EE::API::Entities::List')
::API::Entities::MergeRequestBasic.prepend_if_ee('EE::API::Entities::MergeRequestBasic', with_descendants: true)
::API::Entities::Member.prepend_if_ee('EE::API::Entities::Member', with_descendants: true)
::API::Entities::Namespace.prepend_if_ee('EE::API::Entities::Namespace')
::API::Entities::Project.prepend_if_ee('EE::API::Entities::Project', with_descendants: true)
::API::Entities::ProtectedRefAccess.prepend_if_ee('EE::API::Entities::ProtectedRefAccess')
::API::Entities::UserPublic.prepend_if_ee('EE::API::Entities::UserPublic', with_descendants: true)
::API::Entities::Todo.prepend_if_ee('EE::API::Entities::Todo')
::API::Entities::ProtectedBranch.prepend_if_ee('EE::API::Entities::ProtectedBranch')
::API::Entities::Identity.prepend_if_ee('EE::API::Entities::Identity')
::API::Entities::UserWithAdmin.prepend_if_ee('EE::API::Entities::UserWithAdmin', with_descendants: true)
