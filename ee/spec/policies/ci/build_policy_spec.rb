require 'spec_helper'

describe Ci::BuildPolicy do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }

  let(:policy) do
    described_class.new(user, build)
  end

  describe 'rules for protected environments' do
    let(:environment) { create(:environment, project: project, name: 'production') }
    let(:build) { create(:ci_build, pipeline: pipeline, environment: 'production', ref: 'development') }

    context 'when environment is protected' do
      let(:protected_environment) { create(:protected_environment, name: 'production', project: project) }

      before do
        project.add_developer(user)
      end

      context 'when user has been granted access' do
        before do
          protected_environment.deploy_access_levels.create(user_id: user.id)
        end

        it 'should be allowed to update the build' do
          expect(policy).to be_allowed :update_build
        end
      end

      context 'when user has not been granted access' do
        before do
          protected_environment
        end

        it 'should not be allowed to update the build' do
          expect(policy).not_to be_allowed :update_build
        end
      end
    end

    context 'when environment is not protected' do
      before do
        project.add_developer(user)
      end

      it 'should be allowed to update the build' do
        expect(policy).to be_allowed :update_build
      end
    end
  end
end
