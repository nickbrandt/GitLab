# frozen_string_literal: true

class Admin::Geo::SettingsController < Admin::ApplicationSettingsController
  helper ::EE::GeoHelper
  before_action :check_license!, except: :show
  before_action do
    push_frontend_feature_flag(:enable_geo_settings_form_js)
  end

  def show
  end

  protected

  def check_license!
    unless Gitlab::Geo.license_allows?
      render_403
    end
  end
end
