require 'spec_helper'

describe EnvironmentEntity do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:environment) { create(:environment, project: project) }

  let(:entity) do
    described_class.new(environment, request: double(current_user: user, project: project))
  end

  subject { entity.as_json }

  describe '#is_protected' do
    subject { entity.as_json[:is_protected] }

    context 'when environment is protected' do
      before do
        create(:protected_environment, name: environment.name, project: project)
      end

      it { is_expected.to be_truthy }
    end

    context 'when environment is not protected' do
      it { is_expected.to be_falsy }
    end
  end

  describe '#can_deploy' do
    let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

    subject { entity.as_json[:can_deploy] }

    context 'when access has been granted to a user' do
      before do
        protected_environment.deploy_access_levels.create(user: user)
      end

      it { is_expected.to be_truthy }
    end

    context 'when no access has been granted to a user' do
      before do
        protected_environment
      end

      it { is_expected.to be_falsy }
    end

    context 'when the environment is not protected' do
      it { is_expected.to be_truthy }
    end
  end

  describe '#can_stop' do
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:job) { create(:ci_build, pipeline: pipeline, ref: 'development', environment: environment.name) }
    let(:deployment) { create(:deployment, environment: environment, project: project, deployable: job, ref: 'development', sha: project.commit.id) }
    let(:teardown_build) { create(:ci_build, :manual, pipeline: pipeline, name: 'teardown', ref: 'development', environment:environment.name) }
    let(:environment) { create(:environment, project: project) }
    let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

    before do
      project.repository.add_branch(user, 'development', project.commit.id)

      deployment.update_column(:on_stop, teardown_build.name)
      environment.update_attribute(:deployments, [deployment])
      project.add_maintainer(user)
    end

    subject { entity.as_json[:can_stop] }

    context 'when environment is protected' do
      context 'when user has access to the environment' do
        before do
          protected_environment.deploy_access_levels.create(user: user)
        end

        it { is_expected.to be_truthy }
      end

      context 'when user does not have access to the environment' do
        before do
          protected_environment
        end

        it { is_expected.to be_falsy }
      end
    end

    context 'when environment is not protected' do
      it { is_expected.to be_truthy }
    end
  end
end
