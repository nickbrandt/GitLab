# frozen_string_literal: true

module LicenseHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper

  delegate :new_admin_license_path, to: 'Gitlab::Routing.url_helpers'

  def seats_calculation_message(license)
    return unless license.exclude_guests_from_active_count?

    s_("Users with a Guest role or those who don't belong to a Project or Group will not use a seat from your license.")
  end

  def current_license_title
    License.current&.plan&.titleize || 'Core'
  end

  def has_active_license?
    License.current.present?
  end

  def new_trial_url
    return_to_url = CGI.escape(Gitlab.config.gitlab.url)
    uri = URI.parse(::EE::SUBSCRIPTIONS_URL)
    uri.path = '/trials/new'
    uri.query = "return_to=#{return_to_url}&id=#{Base64.strict_encode64(current_user.email)}"
    uri.to_s
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

  def licensed_users(license)
    if license.restricted?(:active_user_count)
      number_with_delimiter(license.restrictions[:active_user_count])
    else
      _('Unlimited')
    end
  end

  def cloud_license_view_data
    {
      buy_subscription_path: ::EE::SUBSCRIPTIONS_PLANS_URL,
      customers_portal_url: ::EE::SUBSCRIPTIONS_MANAGE_URL,
      free_trial_path: new_trial_url,
      has_active_license: (has_active_license? ? 'true' : 'false'),
      license_upload_path: new_admin_license_path,
      license_remove_path: admin_license_path,
      subscription_sync_path: sync_seat_link_admin_license_path,
      congratulation_svg_path: image_path('illustrations/illustration-congratulation-purchase.svg'),
      subscription_activation_banner_callout_name: ::EE::UserCalloutsHelper::CL_SUBSCRIPTION_ACTIVATION
    }
  end

  extend self
end
