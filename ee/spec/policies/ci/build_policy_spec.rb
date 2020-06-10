# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::BuildPolicy do
  using RSpec::Parameterized::TableSyntax

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project, sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0') }

  describe '#update_build?' do
    let(:environment) { create(:environment, project: project, name: 'production') }
    let(:build) { create(:ee_ci_build, pipeline: pipeline, environment: 'production', ref: 'development') }

    subject { user.can?(:update_build, build) }

    it_behaves_like 'protected environments access'

    context 'when a pipeline has manual deployment job' do
      let!(:build) { create(:ee_ci_build, :with_deployment, :manual, :deploy_to_production, pipeline: pipeline) }

      before do
        project.add_developer(user)
      end

      it 'does not expand environment name' do
        allow(build.project).to receive(:protected_environments_feature_available?) { true }
        expect(build.project).to receive(:protected_environment_accessible_to?)
        expect(build).not_to receive(:expanded_environment_name)

        subject
      end
    end
  end
end
