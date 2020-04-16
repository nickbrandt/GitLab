# frozen_string_literal: true

module LicenseHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper

  delegate :new_admin_license_path, to: 'Gitlab::Routing.url_helpers'

  def current_active_user_count
    License.current&.current_active_users_count || active_user_count
  end

  def guest_user_count
    active_user_count - User.active.excluding_guests.count
  end

  def maximum_user_count
    License.current&.maximum_user_count || 0
  end

  def license_message(signed_in: signed_in?, is_admin: current_user&.admin?)
    return unless current_license
    return unless signed_in
    return unless (is_admin && current_license.notify_admins?) || current_license.notify_users?

    message = []

    message << license_message_subject
    message << expiration_blocking_message

    message.reject {|string| string.blank? }.join(' ').html_safe
  end

  def seats_calculation_message
    if current_license&.exclude_guests_from_active_count?
      content_tag :p do
        "Users with a Guest role or those who don't belong to a Project or Group will not use a seat from your license."
      end
    end
  end

  def current_license
    return @current_license if defined?(@current_license)

    @current_license = License.current
  end

  def current_license_title
    @current_license_title ||= License.current ? License.current.plan.titleize : 'Core'
  end

  def new_trial_url
    return_to_url = CGI.escape(Gitlab.config.gitlab.url)
    uri = URI.parse(::EE::SUBSCRIPTIONS_URL)
    uri.path = '/trials/new'
    uri.query = "return_to=#{return_to_url}&id=#{Base64.strict_encode64(current_user.email)}"
    uri.to_s
  end

  def upgrade_plan_url
    group = @project&.group || @group
    if group
      group_billings_path(group)
    else
      profile_billings_path
    end
  end

  def show_promotions?(selected_user = current_user)
    return false unless selected_user

    if Gitlab::CurrentSettings.current_application_settings
      .should_check_namespace_plan?
      true
    else
      license = License.current
      license.nil? || license.expired?
    end
  end

  def show_advanced_search_promotion?
    !Gitlab::CurrentSettings.should_check_namespace_plan? && show_promotions? && show_callout?('promote_advanced_search_dismissed') && !License.feature_available?(:elastic_search)
  end

  def license_app_data
    { data: { active_user_count: active_user_count,
              guest_user_count: guest_user_count,
              licenses_path: api_licenses_url,
              delete_license_path: api_license_url(id: ':id'),
              new_license_path: new_admin_license_path, download_license_path: download_admin_license_path } }
  end

  def api_licenses_url
    expose_url(api_v4_licenses_path)
  end

  def api_license_url(args)
    expose_url(api_v4_license_path(args))
  end

  extend self

  private

  def active_user_count
    User.active.count
  end

  def license_message_subject
    if current_license.expired?
      message = if current_license.block_changes?
                  _('Your subscription has been downgraded')
                else
                  _('Your subscription expired!')
                end
    else
      remaining_days = pluralize(current_license.remaining_days, 'day')

      message = _('Your subscription will expire in %{remaining_days}') % { remaining_days: remaining_days }
    end

    message = content_tag(:strong, message)

    content_tag(:p, message, class: 'mb-2')
  end

  def expiration_blocking_message
    return '' unless current_license.will_block_changes?

    plan_name = current_license.plan.titleize
    strong = "<strong>".html_safe
    strong_close = "</strong>".html_safe

    if current_license.expired?
      if current_license.block_changes?
        message = _('You didn\'t renew your %{strong}%{plan_name}%{strong_close} subscription so it was downgraded to the GitLab Core Plan.') % { plan_name: plan_name, strong: strong, strong_close: strong_close }
      else
        remaining_days = pluralize((current_license.block_changes_at - Date.today).to_i, 'day')

        message = _('No worries, you can still use all the %{strong}%{plan_name}%{strong_close} features for now. You have %{remaining_days} to renew your subscription.') % { plan_name: plan_name, remaining_days: remaining_days, strong: strong, strong_close: strong_close }
      end
    else
      message = _('Your %{strong}%{plan_name}%{strong_close} subscription will expire on %{strong}%{expires_on}%{strong_close}. After that, you will not to be able to create issues or merge requests as well as many other features.') % { expires_on: current_license.expires_at.strftime("%Y-%m-%d"), plan_name: plan_name, strong: strong, strong_close: strong_close }
    end

    content_tag(:p, message.html_safe)
  end
end
