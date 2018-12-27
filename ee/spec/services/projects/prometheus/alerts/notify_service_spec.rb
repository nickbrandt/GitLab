# frozen_string_literal: true

require 'spec_helper'

describe Projects::Prometheus::Alerts::NotifyService do
  set(:user) { create(:user) }
  set(:project) { create(:project) }

  let(:service) { described_class.new(project, user, payload) }
  let(:token_input) { 'token' }
  let(:subject) { service.execute(token_input) }

  shared_examples 'notifies alerts' do
    let(:notification_service) { spy }
    let(:create_events_service) { spy }

    before do
      allow(NotificationService).to receive(:new).and_return(notification_service)
      allow(Projects::Prometheus::Alerts::CreateEventsService)
        .to receive(:new).and_return(create_events_service)
    end

    it 'sends a notification for firing alerts only' do
      expect(notification_service)
        .to receive_message_chain(:async, :prometheus_alerts_fired)
        .with(project, [payload_alert_firing])

      expect(subject).to eq(true)
    end

    it 'persists events' do
      expect(create_events_service).to receive(:execute)

      expect(subject).to eq(true)
    end
  end

  shared_examples 'no notifications' do
    let(:notification_service) { spy }
    let(:create_events_service) { spy }

    it 'does not notify' do
      expect(notification_service).not_to receive(:async)
      expect(create_events_service).not_to receive(:execute)

      expect(subject).to eq(false)
    end
  end

  context 'with valid payload' do
    let(:alert_firing) { create(:prometheus_alert, project: project) }
    let(:alert_resolved) { create(:prometheus_alert, project: project) }
    let(:payload) { payload_for(firing: [alert_firing], resolved: [alert_resolved]) }
    let(:payload_alert_firing) { payload['alerts'].first }
    let(:token) { 'token' }

    context 'with project specific cluster' do
      using RSpec::Parameterized::TableSyntax

      where(:cluster_enabled, :status, :configured_token, :token_input, :result) do
        true  | :installed | token | token | :success
        true  | :installed | nil   | nil   | :success
        true  | :updated   | token | token | :success
        true  | :updating  | token | token | :failure
        true  | :installed | token | 'x'   | :failure
        true  | :installed | nil   | token | :failure
        true  | :installed | token | nil   | :failure
        true  | nil        | token | token | :failure
        false | :installed | token | token | :failure
      end

      with_them do
        let(:alert_manager_token) { token_input }

        before do
          cluster = create(:cluster, :provided_by_user,
                           projects: [project],
                           enabled: cluster_enabled)

          if status
            create(:clusters_applications_prometheus, status,
                   cluster: cluster,
                   alert_manager_token: configured_token)
          end
        end

        case result = params[:result]
        when :success
          it_behaves_like 'notifies alerts'
        when :failure
          it_behaves_like 'no notifications'
        else
          raise "invalid result: #{result.inspect}"
        end
      end
    end

    context 'with environment specific clusters' do
      let(:prd_cluster) do
        create(:cluster, :provided_by_user, projects: [project], enabled: true, environment_scope: '*')
      end
      let(:stg_cluster) do
        create(:cluster, :provided_by_user, projects: [project], enabled: true, environment_scope: 'stg/*')
      end

      let(:stg_environment) do
        create(:environment, project: project, name: 'stg/1')
      end

      let(:alert_firing) do
        create(:prometheus_alert, project: project, environment: stg_environment)
      end

      before do
        stub_licensed_features(multiple_clusters: true)

        create(:clusters_applications_prometheus, :installed,
               cluster: prd_cluster, alert_manager_token: token)
        create(:clusters_applications_prometheus, :installed,
               cluster: stg_cluster, alert_manager_token: nil)
      end

      context 'without token' do
        let(:token_input) { nil }

        it_behaves_like 'notifies alerts'
      end

      context 'with token' do
        it_behaves_like 'no notifications'
      end
    end

    context 'without project specific cluster' do
      let!(:cluster) { create(:cluster, enabled: true) }

      it_behaves_like 'no notifications'
    end

    context 'with manual prometheus installation' do
      before do
        create(:prometheus_service, project: project)
      end

      it_behaves_like 'notifies alerts'
    end
  end

  context 'with invalid payload' do
    context 'without version' do
      let(:payload) { {} }

      it_behaves_like 'no notifications'
    end

    context 'when version is not "4"' do
      let(:payload) { { 'version' => '5' } }

      it_behaves_like 'no notifications'
    end
  end

  private

  def payload_for(firing: [], resolved: [])
    status = firing.any? ? 'firing' : 'resolved'
    alerts = firing + resolved
    alert_name = alerts.first.title
    prometheus_metric_id = alerts.first.prometheus_metric_id.to_s

    alerts_map = \
      firing.map { |alert| map_alert_payload('firing', alert) } +
      resolved.map { |alert| map_alert_payload('resolved', alert) }

    # See https://prometheus.io/docs/alerting/configuration/#%3Cwebhook_config%3E
    {
      'version' => '4',
      'receiver' => 'gitlab',
      'status' => status,
      'alerts' => alerts_map,
      'groupLabels' => {
        'alertname' => alert_name
      },
      'commonLabels' => {
        'alertname' => alert_name,
        'gitlab' => 'hook',
        'gitlab_alert_id' => prometheus_metric_id
      },
      'commonAnnotations' => {},
      'externalURL' => '',
      'groupKey' => "{}:{alertname=\'#{alert_name}\'}"
    }
  end

  def map_alert_payload(status, alert)
    {
      'status' => status,
      'labels' => {
        'alertname' => alert.title,
        'gitlab' => 'hook',
        'gitlab_alert_id' => alert.prometheus_metric_id.to_s
      },
      'annotations' => {},
      'startsAt' => '2018-09-24T08:57:31.095725221Z',
      'endsAt' => '0001-01-01T00:00:00Z',
      'generatorURL' => 'http://prometheus-prometheus-server-URL'
    }
  end
end
