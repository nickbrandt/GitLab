# frozen_string_literal: true

require 'spec_helper'

describe 'Metrics rendering', :js, :use_clean_rails_memory_store_caching, :sidekiq_inline do
  include PrometheusHelpers
  include MetricsDashboardUrlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:prometheus_project) }

  let(:issue) { create(:issue, project: project, description: description) }

  before do
    clear_host_from_memoized_variables

    allow(::Gitlab.config.gitlab)
      .to receive(:url)
      .and_return(urls.root_url.chomp('/'))

    stub_licensed_features(prometheus_alerts: true)

    project.add_maintainer(user)
    sign_in(user)

    import_common_metrics
    stub_any_prometheus_request_with_response
  end

  after do
    clear_host_from_memoized_variables
  end

  # This context block can be moved as-is to inside the
  # 'internal metrics embeds' block in spec/features/markdown/metrics_spec.rb
  # while migrating alerting to CE. Add `:alert_regex` to
  # clear_host_from_memoized_variables
  context 'for GitLab-managed alerting rules' do
    let(:metric) { PrometheusMetric.last }
    let!(:alert) { create(:prometheus_alert, project: project, prometheus_metric: metric) }

    let(:description) { "# Summary \n[](#{metrics_url})" }
    let(:metrics_url) do
      urls.metrics_dashboard_project_prometheus_alert_url(
        project,
        metric.id,
        environment_id: alert.environment_id,
        embedded: true
      )
    end

    it 'shows embedded metrics' do
      visit project_issue_path(project, issue)

      expect(page).to have_css('div.prometheus-graph')
      expect(page).to have_text(metric.title)
      expect(page).to have_text(metric.y_label)
      expect(page).not_to have_text(metrics_url)
    end
  end

  def import_common_metrics
    ::Gitlab::DatabaseImporters::CommonMetrics::Importer.new.execute
  end
end
