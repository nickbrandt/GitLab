# frozen_string_literal: true

module Types
  class AccessLevelEnum < BaseEnum
    graphql_name 'AccessLevelEnum'
    description 'Access level to a resource'

    value 'NO_ACCESS', description: 'No access (usually indicates sign-in is necessary)', value: Gitlab::Access::NO_ACCESS
    value 'GUEST', description: 'Guest access to public environments', value: Gitlab::Access::GUEST
    value 'REPORTER', description: 'Reporter access to public environments', value: Gitlab::Access::REPORTER
    value 'DEVELOPER', description: 'Developer access (includes maintainers)', value: Gitlab::Access::DEVELOPER
    value 'MAINTAINER', description: 'Maintainer access', value: Gitlab::Access::MAINTAINER
    value 'OWNER', description: 'Code owner access (administrator access)', value: Gitlab::Access::OWNER
  end
end
