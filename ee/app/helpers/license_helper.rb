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

    is_trial = current_license.trial?

    message << license_message_subject(is_trial: is_trial)
    message << trial_purchase_message if is_trial
    message << expiration_blocking_message(is_admin: is_admin)
    message << renewal_instructions_message unless is_trial

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

  def license_message_subject(is_trial:)
    message = []

    if current_license.expired?
      expires_at = current_license.expires_at

      message << if is_trial
                   _('Your trial license expired on %{expires_at}.') % { expires_at: expires_at }
                 else
                   _('Your license expired on %{expires_at}.') % { expires_at: expires_at }
                 end
    else
      remaining_days = pluralize(current_license.remaining_days, 'day')

      message << if is_trial
                   _('Your trial license will expire in %{remaining_days}.') % { remaining_days: remaining_days }
                 else
                   _('Your license will expire in %{remaining_days}.') % { remaining_days: remaining_days }
                 end
    end

    message.join(' ')
  end

  def trial_purchase_message
    buy_now_url = ::EE::SUBSCRIPTIONS_PLANS_URL
    buy_now_link_start = "<a href='#{buy_now_url}' target='_blank' rel='noopener'>".html_safe
    link_end = '</a>'.html_safe

    _('%{buy_now_link_start}Buy now!%{link_end}') % { buy_now_link_start: buy_now_link_start, link_end: link_end }
  end

  def expiration_blocking_message(is_admin:)
    return '' unless current_license.expired? && current_license.will_block_changes?

    message = []

    message << if current_license.block_changes?
                 _('Pushing code and creation of issues and merge requests has been disabled.')
               else
                 _('Pushing code and creation of issues and merge requests will be disabled on %{disabled_on}.') % { disabled_on: current_license.block_changes_at }
               end

    message << if is_admin

                 if current_license.block_changes?
                   _('Upload a new license in the admin area to restore service.')
                 else
                   _('Upload a new license in the admin area to ensure uninterrupted service.')
                 end
               else
                 if current_license.block_changes?
                   _('Ask an admin to upload a new license to restore service.')
                 else
                   _('Ask an admin to upload a new license to ensure uninterrupted service.')
                 end
               end

    message.join(' ')
  end

  def renewal_instructions_message
    renewal_faq_url = 'https://docs.gitlab.com/ee/subscriptions/#renew-your-subscription'

    renewal_faq_link_start = "<a href='#{renewal_faq_url}' target='_blank' rel='noopener'>".html_safe
    link_end = '</a>'.html_safe

    _('For renewal instructions %{link_start}view our Licensing FAQ.%{link_end}') % { link_start: renewal_faq_link_start, link_end: link_end }
  end
end
