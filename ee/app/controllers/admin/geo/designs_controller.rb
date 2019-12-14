# frozen_string_literal: true

class Admin::Geo::DesignsController < Admin::Geo::ApplicationController
  before_action :check_license!

  before_action do
    push_frontend_feature_flag(:enable_geo_design_sync)
  end

  def index
  end
end
