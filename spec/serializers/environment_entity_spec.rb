require 'spec_helper'

describe EnvironmentEntity do
  include KubernetesHelpers

  let(:user) { create(:user) }
  let(:environment) { create(:environment) }

  let(:entity) do
    described_class.new(environment, request: double(current_user: user))
  end

  subject { entity.as_json }

  before do
    environment.project.add_maintainer(user)
  end

  it 'exposes latest deployment' do
    expect(subject).to include(:last_deployment)
  end

  it 'exposes core elements of environment' do
    expect(subject).to include(:id, :name, :state, :environment_path)
  end

  it 'exposes folder path' do
    expect(subject).to include(:folder_path)
  end

  context 'metrics disabled' do
    before do
      allow(environment).to receive(:has_metrics?).and_return(false)
    end

    it "doesn't expose metrics path" do
      expect(subject).not_to include(:metrics_path)
    end
  end

  context 'metrics enabled' do
    before do
      allow(environment).to receive(:has_metrics?).and_return(true)
    end

    it 'exposes metrics path' do
      expect(subject).to include(:metrics_path)
    end
  end

  context 'with deployment service ready' do
    before do
      stub_licensed_features(deploy_board: true)
      allow(environment).to receive(:has_terminals?).and_return(true)
      allow(environment).to receive(:rollout_status).and_return(kube_deployment_rollout_status)
    end

    it 'exposes rollout_status' do
      expect(subject).to include(:rollout_status)
    end
  end

  context 'when license does not has the GitLab_DeployBoard add-on' do
    before do
      stub_licensed_features(deploy_board: false)
      allow(environment).to receive(:has_terminals?).and_return(true)
    end

    it 'does not expose rollout_status' do
      expect(subject[:rollout_status_path]).to be_blank
    end
  end

  context 'with deployment platform' do
    let(:project) { create(:project, :repository) }
    let(:environment) { create(:environment, project: project) }

    context 'when deployment platform is a cluster' do
      before do
        create(:cluster,
               :provided_by_gcp,
               :project,
               environment_scope: '*',
               projects: [project])
      end

      it 'should include cluster_type' do
        expect(subject).to include(:cluster_type)
        expect(subject[:cluster_type]).to eq('project_type')
      end
    end

    context 'when deployment platform is a Kubernetes Service' do
      before do
        create(:kubernetes_service, project: project)
      end

      it 'should not include cluster_type' do
        expect(subject).not_to include(:cluster_type)
      end
    end
  end
end
