# frozen_string_literal: true

module EE
  module NamespacesHelper
    def namespace_extra_shared_runner_limits_quota(namespace)
      report = namespace.ci_minutes_quota.purchased_minutes_report

      content_tag(:span, class: "shared_runners_limit_#{report.status}") do
        "#{report.used} / #{report.limit}"
      end
    end

    def namespace_shared_runner_limits_quota(namespace)
      report = namespace.ci_minutes_quota.monthly_minutes_report

      content_tag(:span, class: "shared_runners_limit_#{report.status}") do
        "#{report.used} / #{report.limit}"
      end
    end

    def namespace_extra_shared_runner_limits_percent_used(namespace)
      limit = namespace.extra_shared_runners_minutes_limit.to_i

      return 0 if limit.zero?

      100 * namespace.extra_shared_runners_minutes.to_i / limit
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

    def namespace_extra_shared_runner_limits_progress_bar(namespace)
      used = namespace_extra_shared_runner_limits_percent_used(namespace)
      percent = [used, 100].min

      namespace_shared_runner_usage_progress_bar(percent)
    end

    def ci_minutes_progress_bar(percent)
      status =
        if percent >= 100
          'danger'
        elsif percent >= 80
          'warning'
        else
          'success'
        end

      width = [percent, 100].min

      options = {
        class: "progress-bar bg-#{status}",
        style: "width: #{width}%;"
      }

      content_tag :div, class: 'progress' do
        content_tag :div, nil, options
      end
    end
  end
end
