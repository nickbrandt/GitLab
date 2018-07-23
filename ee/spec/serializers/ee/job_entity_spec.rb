require 'spec_helper'

describe JobEntity do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:request) { double('request') }
  let(:entity) { described_class.new(job, request: request) }
  let(:environment) { create(:environment, project: project) }

  subject { entity.as_json }

  before do
    allow(request).to receive(:current_user).and_return(user)
  end

  describe '#playable?' do
    before do
      project.add_developer(user)
    end

    context 'for protected environments' do
      let(:protected_environment) { create(:protected_environment, project: project, name: environment.name) }
      let(:job) { create(:ci_build, :manual, project: project, environment: environment.name, ref: 'development') }

      context 'when user does not have access to it' do
        before do
          protected_environment
        end

        it 'should set playable as false' do
          expect(subject[:playable]).to be_falsy
        end
      end

      context 'when user has access to it' do
        before do
          protected_environment.deploy_access_levels.create(user: user)
        end

        it 'should set playable as true' do
          expect(subject[:playable]).to be_truthy
        end
      end
    end
  end

  describe '#retryable?' do
    before do
      project.add_developer(user)
    end

    context 'when user does not have access to it' do
      let(:protected_environment) { create(:protected_environment, project: project, name: environment.name) }
      let(:job) { create(:ci_build, :failed, project: project, environment: environment.name, ref: 'development') }

      before do
        protected_environment
      end

      it 'should not include retry_path' do
        expect(subject).to_not include(:retry_path)
      end
    end

    context 'when user has access to it' do
      before do
        protected_environment.deploy_access_levels.create(user: user)
      end

      it 'should include retry path' do
        expect(subject).to include(:retry_path)
      end
    end
  end
end
