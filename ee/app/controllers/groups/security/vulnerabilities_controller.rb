# frozen_string_literal: true

class Groups::Security::VulnerabilitiesController < Groups::Security::ApplicationController
  include VulnerabilitiesActions

  private

  def vulnerable
    group
  end
end
