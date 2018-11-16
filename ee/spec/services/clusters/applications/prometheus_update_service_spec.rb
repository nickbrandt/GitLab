require 'spec_helper'

describe Clusters::Applications::PrometheusUpdateService do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:environment) { create(:environment, project: project) }
    let(:cluster) { create(:cluster, :provided_by_user, :with_installed_helm, projects: [project]) }
    let(:application) { create(:clusters_applications_prometheus, :installed, cluster: cluster) }
    let!(:get_command_values) { OpenStruct.new(data: OpenStruct.new('values.yaml': application.values)) }
    let!(:upgrade_command) { application.upgrade_command("") }
    let(:upgrade_values_yaml) { StringIO.new }
    let(:upgrade_values) { YAML.safe_load(upgrade_values_yaml.string) }
    let(:helm_client) { instance_double(::Gitlab::Kubernetes::Helm::Api) }

    subject(:service) { described_class.new(application, project) }

    before do
      allow(service)
        .to receive(:upgrade_command) { |values| upgrade_values_yaml.write(values) }
        .and_return(upgrade_command)
      allow(service).to receive(:helm_api).and_return(helm_client)
    end

    context 'when there are no errors' do
      before do
        expect(helm_client).to receive(:get_config_map).with("values-content-configuration-prometheus").and_return(get_command_values)
        expect(helm_client).to receive(:update).with(upgrade_command)
        allow(::ClusterWaitForAppUpdateWorker).to receive(:perform_in).and_return(nil)
      end

      context 'when prometheus alerts exist' do
        let(:metric) do
          query = 'pod_name=~"^%{ci_environment_slug}",' \
            'namespace="%{kube_namespace}",' \
            '%{environment_filter}'

          create(:prometheus_metric, project: project, query: query)
        end

        let!(:alert) do
          create(:prometheus_alert,
                 project: project,
                 environment: environment,
                 prometheus_metric: metric)
        end

        it 'generates the alert manager values' do
          service.execute

          expect(upgrade_values.dig('alertmanager', 'enabled')).to eq(true)

          alertmanager = upgrade_values.dig('alertmanagerFiles', 'alertmanager.yml')
          expect(alertmanager).not_to be_nil
          expect(alertmanager.dig('receivers', 0, 'name')).to eq('gitlab')
          expect(alertmanager.dig('route', 'receiver')).to eq('gitlab')

          alerts = upgrade_values.dig('serverFiles', 'alerts', 'groups')
          expect(alerts).not_to be_nil
          expect(alerts.size).to eq(1)
          expect(alerts.dig(0, 'name')).to eq("#{environment.name}.rules")
          expect(alerts.dig(0, 'rules', 0, 'expr')).to include(
            environment.slug,
            environment.deployment_platform.actual_namespace,
            %{container_name!="POD",environment="#{environment.slug}"}
          )
        end
      end

      context 'when prometheus alerts do not exist' do
        it 'resets the alert manager values' do
          service.execute

          expect(upgrade_values.dig('alertmanager', 'enabled')).to eq(false)
          expect(upgrade_values).not_to include('alertmanagerFiles')
          expect(upgrade_values.dig('serverFiles', 'alerts')).to eq({})
        end
      end

      it 'make the application updating' do
        expect(application.cluster).not_to be_nil

        service.execute

        expect(application).to be_updating
      end

      it 'schedules async update status check' do
        expect(::ClusterWaitForAppUpdateWorker).to receive(:perform_in).once

        service.execute
      end
    end

    context 'when k8s cluster communication fails' do
      it 'make the application update errored' do
        error = ::Kubeclient::HttpError.new(500, 'system failure', nil)
        allow(helm_client).to receive(:get_config_map).and_raise(error)

        service.execute

        expect(application).to be_update_errored
        expect(application.status_reason).to match(/kubernetes error:/i)
      end
    end

    context 'when application cannot be persisted' do
      let(:application) { build(:clusters_applications_prometheus, :installed) }

      it 'make the application update errored' do
        allow(application).to receive(:make_updating!).once.and_raise(ActiveRecord::RecordInvalid)

        expect(helm_client).not_to receive(:get_config_map)
        expect(helm_client).not_to receive(:update)

        service.execute

        expect(application).to be_update_errored
      end
    end
  end
end
