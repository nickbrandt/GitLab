# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Url do
  describe '#clusters_regex' do
    let(:url) do
      Gitlab::Routing.url_helpers.namespace_project_cluster_url(
        'foo',
        'bar',
        '1',
        group: 'Cluster Health',
        title: 'Memory Usage',
        y_label: 'Memory 20(GiB)',
        anchor: 'title'
      )
    end

    let(:expected_params) do
      {
        'url' => url,
        'namespace' => 'foo',
        'project' => 'bar',
        'cluster_id' => '1',
        'query' => '?group=Cluster+Health&title=Memory+Usage&y_label=Memory+20%28GiB%29',
        'anchor' => '#title'
      }
    end

    subject { described_class.clusters_regex }

    it_behaves_like 'regex which matches url when expected'
  end

  describe '#alert_regex' do
    let(:url) do
      Gitlab::Routing.url_helpers.metrics_dashboard_namespace_project_prometheus_alert_url(
        'foo',
        'bar',
        '1',
        start: '2020-02-10T12:59:49.938Z',
        end: '2020-02-10T20:59:49.938Z',
        anchor: "anchor"
      )
    end

    let(:expected_params) do
      {
        'url' => url,
        'namespace' => 'foo',
        'project' => 'bar',
        'alert' => '1',
        'query' => "?end=2020-02-10T20%3A59%3A49.938Z&start=2020-02-10T12%3A59%3A49.938Z",
        'anchor' => '#anchor'
      }
    end

    subject { described_class.alert_regex }

    it_behaves_like 'regex which matches url when expected'
  end
end
