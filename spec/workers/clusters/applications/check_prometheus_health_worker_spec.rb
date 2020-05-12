# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::CheckPrometheusHealthWorker, '#perform' do
  subject { described_class.new.perform }

  it 'triggers health service' do
    cluster = create(:cluster)
    allow(Gitlab::Monitor::DemoProjects).to receive(:oids)
    allow(Clusters::Cluster).to receive(:with_application_prometheus).and_return(double(with_project_alert_service_data: [cluster]))

    service_instance = instance_double(Clusters::Applications::PrometheusHealthCheckService)
    expect(Clusters::Applications::PrometheusHealthCheckService).to receive(:new).with(cluster).and_return(service_instance)
    expect(service_instance).to receive(:execute)

    subject
  end
end
