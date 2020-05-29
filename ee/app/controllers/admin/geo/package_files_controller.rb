# frozen_string_literal: true

class Admin::Geo::PackageFilesController < Admin::Geo::ApplicationController
  before_action :check_license!
  before_action do
    push_frontend_feature_flag(:geo_self_service_framework)
  end

  def index
  end
end
