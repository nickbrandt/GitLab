# frozen_string_literal: true

class Groups::Security::VulnerabilitiesController < Groups::Security::ApplicationController
  include ::EE::VulnerabilitiesActions # rubocop: disable Cop/InjectEnterpriseEditionModule
end
