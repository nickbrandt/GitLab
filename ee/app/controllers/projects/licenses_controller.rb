# frozen_string_literal: true

module Projects
  class LicensesController < Projects::ApplicationController
    before_action :authorize_read_licenses_list!
  end
end
