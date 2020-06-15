# frozen_string_literal: true

module EE
  module NamespacesHelper
    extend ::Gitlab::Utils::Override

    def ci_minutes_report(quota_report)
      content_tag(:span, class: "shared_runners_limit_#{quota_report.status}") do
        "#{quota_report.used} / #{quota_report.limit}"
      end
    end

    def ci_minutes_progress_bar(percent)
      status =
        if percent >= 95
          'danger'
        elsif percent >= 70
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

    override :namespace_storage_usage_link
    def namespace_storage_usage_link(namespace)
      if namespace.group?
        group_usage_quotas_path(namespace, anchor: 'storage-quota-tab')
      else
        profile_usage_quotas_path(anchor: 'storage-quota-tab')
      end
    end
  end
end
