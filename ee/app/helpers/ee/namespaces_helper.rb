# frozen_string_literal: true

module EE
  module NamespacesHelper
    def namespace_extra_shared_runner_limits_quota(namespace)
      report = ::Ci::Minutes::Quota.new(namespace).purchased_minutes_report

      content_tag(:span, class: "shared_runners_limit_#{report.status}") do
        "#{report.used} / #{report.limit}"
      end
    end

    def namespace_shared_runner_limits_quota(namespace)
      report = ::Ci::Minutes::Quota.new(namespace).monthly_minutes_report

      content_tag(:span, class: "shared_runners_limit_#{report.status}") do
        "#{report.used} / #{report.limit}"
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
