# frozen_string_literal: true

class IssueSidebarEntity < IssuableSidebarEntity
  prepend ::EE::IssueSidebarEntity # rubocop: disable Cop/InjectEnterpriseEditionModule

  expose :assignees, using: API::Entities::UserBasic
end
