# frozen_string_literal: true

module Projects
  class LicensesController < Projects::ApplicationController
    before_action :authorize_read_licenses!

    before_action do
      push_frontend_feature_flag(:licenses_list)
    end
  end
end
