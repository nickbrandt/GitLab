# frozen_string_literal: true

module EE
  module NamespacesHelper
    def namespace_extra_shared_runner_limits_quota(namespace)
      limit = namespace.extra_shared_runners_minutes_limit.to_i
      used = namespace.extra_shared_runners_minutes.to_i
      status = namespace.extra_shared_runners_minutes_used? ? 'over_quota' : 'under_quota'

      content_tag(:span, class: "shared_runners_limit_#{status}") do
        "#{used} / #{limit}"
      end
    end

    def namespace_shared_runner_limits_quota(namespace)
      used = namespace.shared_runners_minutes(include_extra: false).to_i

      if namespace.shared_runners_minutes_limit_enabled?
        limit = namespace.actual_shared_runners_minutes_limit(include_extra: false)
        status = namespace.shared_runners_minutes_used? ? 'over_quota' : 'under_quota'
      else
        limit = 'Unlimited'
        status = 'disabled'
      end

      content_tag(:span, class: "shared_runners_limit_#{status}") do
        "#{used} / #{limit}"
      end
    end

    def namespace_extra_shared_runner_limits_percent_used(namespace)
      limit = namespace.extra_shared_runners_minutes_limit.to_i

      return 0 if limit.zero?

      100 * namespace.extra_shared_runners_minutes.to_i / limit
    end

    def namespace_shared_runner_limits_percent_used(namespace)
      return 0 unless namespace.shared_runners_minutes_limit_enabled?

      100 * namespace.shared_runners_minutes(include_extra: false).to_i / namespace.actual_shared_runners_minutes_limit(include_extra: false)
    end

    def namespace_shared_runner_usage_progress_bar(percent)
      status =
        if percent == 100
          'danger'
        elsif percent >= 80
          'warning'
        else
          'success'
        end

      options = {
        class: "progress-bar bg-#{status}",
        style: "width: #{percent}%;"
      }

      content_tag :div, class: 'progress' do
        content_tag :div, nil, options
      end
    end

    def namespace_shared_runner_limits_progress_bar(namespace, extra: false)
      used = extra ? namespace_extra_shared_runner_limits_percent_used(namespace) : namespace_shared_runner_limits_percent_used(namespace)
      percent = [used, 100].min

      namespace_shared_runner_usage_progress_bar(percent)
    end
  end
end
