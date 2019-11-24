# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::Sentry do
  include_examples 'cluster application core specs', :clusters_applications_sentry
  include_examples 'cluster application status specs', :clusters_applications_sentry
  include_examples 'cluster application version specs', :clusters_applications_sentry
  include_examples 'cluster application helm specs', :clusters_applications_sentry

  describe '#can_uninstall?' do
    let(:ingress) { create(:clusters_applications_ingress, :installed, external_hostname: 'localhost.localdomain') }
    let(:sentry) { create(:clusters_applications_sentry, cluster: ingress.cluster) }

    subject { sentry.can_uninstall? }

    it { is_expected.to be_truthy }
  end

  describe '#set_initial_status' do
    before do
      sentry.set_initial_status
    end

    context 'when ingress is not installed' do
      let(:cluster) { create(:cluster, :provided_by_gcp) }
      let(:sentry) { create(:clusters_applications_sentry, cluster: cluster) }

      it { expect(sentry).to be_not_installable }
    end

    context 'when ingress is installed and external_ip is assigned' do
      let(:ingress) { create(:clusters_applications_ingress, :installed, external_ip: '127.0.0.1') }
      let(:sentry) { create(:clusters_applications_sentry, cluster: ingress.cluster) }

      it { expect(sentry).to be_installable }
    end

    context 'when ingress is installed and external_hostname is assigned' do
      let(:ingress) { create(:clusters_applications_ingress, :installed, external_hostname: 'localhost.localdomain') }
      let(:sentry) { create(:clusters_applications_sentry, cluster: ingress.cluster) }

      it { expect(sentry).to be_installable }
    end
  end

  describe '#install_command' do
    let!(:ingress) { create(:clusters_applications_ingress, :installed, external_ip: '127.0.0.1') }
    let(:sentry) { create(:clusters_applications_sentry, cluster: ingress.cluster) }

    subject { sentry.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'is initialized with 4 arguments' do
      expect(subject.name).to eq('sentry')
      expect(subject.chart).to eq('stable/sentry')
      expect(subject.version).to eq('3.1.1')
      expect(subject).to be_rbac
      expect(subject.files).to eq(sentry.files)
    end

    context 'on a non rbac enabled cluster' do
      before do
        sentry.cluster.platform_kubernetes.abac!
      end

      it { is_expected.not_to be_rbac }
    end

    context 'application failed to install previously' do
      let(:se) { create(:clusters_applications_sentry, :errored, version: '0.0.1') }

      it 'is initialized with the locked version' do
        expect(subject.version).to eq('3.1.1')
      end
    end
  end

  describe '#files' do
    let(:cluster) { create(:cluster, :with_installed_helm, :provided_by_gcp, :project) }
    let(:application) { create(:clusters_applications_sentry, cluster: cluster) }
    let(:values) { subject[:'values.yaml'] }

    subject { application.files }

    context 'when cluster belongs to a project' do
      it 'includes valid values' do
        expect(values).to include('ingress')
        expect(values).to include('service')
        expect(values).to include('user')
      end
    end

    context 'when cluster belongs to a group' do
      let(:group) { create(:group) }
      let(:cluster) { create(:cluster, :with_installed_helm, :provided_by_gcp, :group, groups: [group]) }

      it 'includes valid values' do
        expect(values).to include('ingress')
        expect(values).to include('service')
        expect(values).to include('user')
      end
    end
  end
end
