# frozen_string_literal: true

module Gitlab
  class ExpiringSubscriptionMessage
    include ActionView::Helpers::TextHelper

    attr_reader :subscribable, :signed_in, :is_admin, :namespace

    def initialize(subscribable:, signed_in:, is_admin:, namespace: nil)
      @subscribable = subscribable
      @signed_in = signed_in
      @is_admin = is_admin
      @namespace = namespace
    end

    def message
      return unless notifiable?

      message = []
      message << license_message_subject if license_message_subject.present?
      message << expiration_blocking_message if expiration_blocking_message.present?

      message.join(' ').html_safe
    end

    private

    def license_message_subject
      message = subscribable.expired? ? expired_subject : expiring_subject

      message = content_tag(:strong, message)

      content_tag(:p, message, class: 'mb-2')
    end

    def expired_subject
      if subscribable.block_changes?
        _('Your subscription has been downgraded')
      else
        _('Your subscription expired!')
      end
    end

    def expiring_subject
      remaining_days = pluralize(subscribable.remaining_days, 'day')

      _('Your subscription will expire in %{remaining_days}') % { remaining_days: remaining_days }
    end

    def expiration_blocking_message
      return '' unless subscribable.will_block_changes?

      message = subscribable.expired? ? expired_message : expiring_message

      content_tag(:p, message.html_safe)
    end

    def expired_message
      if subscribable.block_changes?
        if namespace
          _('You didn\'t renew your %{strong}%{plan_name}%{strong_close} subscription for %{strong}%{namespace_name}%{strong_close} so it was downgraded to the free plan.') % { plan_name: plan_name, strong: strong, strong_close: strong_close, namespace_name: namespace.name }
        else
          _('You didn\'t renew your %{strong}%{plan_name}%{strong_close} subscription so it was downgraded to the GitLab Core Plan.') % { plan_name: plan_name, strong: strong, strong_close: strong_close }
        end
      else
        remaining_days = pluralize((subscribable.block_changes_at - Date.today).to_i, 'day')

        _('No worries, you can still use all the %{strong}%{plan_name}%{strong_close} features for now. You have %{remaining_days} to renew your subscription.') % { plan_name: plan_name, remaining_days: remaining_days, strong: strong, strong_close: strong_close }
      end
    end

    def expiring_message
      if namespace
        _('Your %{strong}%{plan_name}%{strong_close} subscription for %{strong}%{namespace_name}%{strong_close} will expire on %{strong}%{expires_on}%{strong_close}. After that, you will not to be able to create issues or merge requests as well as many other features.') % { expires_on: subscribable.expires_at.strftime("%Y-%m-%d"), plan_name: plan_name, strong: strong, strong_close: strong_close, namespace_name: namespace.name }
      else
        _('Your %{strong}%{plan_name}%{strong_close} subscription will expire on %{strong}%{expires_on}%{strong_close}. After that, you will not to be able to create issues or merge requests as well as many other features.') % { expires_on: subscribable.expires_at.strftime("%Y-%m-%d"), plan_name: plan_name, strong: strong, strong_close: strong_close }
      end
    end

    def notifiable?
      subscribable &&
        signed_in &&
        ((is_admin && subscribable.notify_admins?) || subscribable.notify_users?) &&
        expired_subscribable_within_notification_window?
    end

    def expired_subscribable_within_notification_window?
      return true unless subscribable.expired?

      expired_at = subscribable.expires_at
      (expired_at..(expired_at + 30.days)).cover?(Date.today)
    end

    def plan_name
      subscribable.plan.titleize
    end

    def strong
      '<strong>'.html_safe
    end

    def strong_close
      '</strong>'.html_safe
    end
  end
end
