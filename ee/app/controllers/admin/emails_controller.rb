# frozen_string_literal: true

class Admin::EmailsController < Admin::ApplicationController
  include Admin::EmailsHelper

  before_action :check_license_send_emails_from_admin_area_available!

  def show
  end

  def create
    AdminEmailsWorker.perform_async(params[:recipients], params[:subject], params[:body]) # rubocop:disable CodeReuse/Worker
    redirect_to admin_email_path, notice: 'Email sent'
  end

  private

  def check_license_send_emails_from_admin_area_available!
    render_404 unless send_emails_from_admin_area_feature_available?
  end
end
