# frozen_string_literal: true

class Admin::IntegrationsController < Admin::ApplicationController
  include ServiceParams

  before_action :set_integration, only: [:edit, :update, :test]

  def edit
  end

  def update
    if @service.update(service_params[:service])
      redirect_to edit_admin_application_settings_integration_path(@service), notice: success_message
    else
      render :edit
    end
  end

  def test
  end

  private

  def set_integration
    @service ||= Project.first.find_or_initialize_service(params[:id])
  end

  def success_message
    if @service.active?
      _('%{service_title} activated.') % { service_title: @service.title }
    else
      _('%{service_title} settings saved, but not activated.') % { service_title: @service.title }
    end
  end
end
