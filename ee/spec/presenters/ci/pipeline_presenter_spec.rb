# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelinePresenter do
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:pipeline, reload: true) { create(:ee_ci_pipeline, project: project) }

  let(:presenter) { described_class.new(pipeline) }

  describe '#failure_reason' do
    context 'when pipeline has failure reason' do
      it 'represents a failure reason sentence' do
        pipeline.failure_reason = :activity_limit_exceeded

        expect(presenter.failure_reason)
          .to eq 'Pipeline activity limit exceeded!'
      end
    end

    context 'when pipeline does not have failure reason' do
      it 'returns nil' do
        expect(presenter.failure_reason).to be_nil
      end
    end
  end

  describe '#expose_security_dashboard?' do
    subject { presenter.expose_security_dashboard? }

    let(:current_user) { create(:user) }

    before do
      allow(presenter).to receive(:current_user) { current_user }
    end

    context 'with developer' do
      before do
        project.add_developer(current_user)
      end

      context 'when features are available' do
        before do
          stub_licensed_features(dependency_scanning: true, license_scanning: true, security_dashboard: true)
        end

        context 'when there is an artifact of a right type' do
          let!(:build) { create(:ee_ci_build, :dependency_scanning, pipeline: pipeline) }

          it { is_expected.to be_truthy }
        end

        context 'when there is an artifact of a wrong type' do
          let!(:build) { create(:ee_ci_build, :license_scanning, pipeline: pipeline) }

          it { is_expected.to be_falsey }
        end

        context 'when there is no found artifact' do
          let!(:build) { create(:ee_ci_build, pipeline: pipeline) }

          it { is_expected.to be_falsey }
        end
      end

      context 'when features are disabled' do
        context 'when there is an artifact of a right type' do
          let!(:build) { create(:ee_ci_build, :dependency_scanning, pipeline: pipeline) }

          it { is_expected.to be_falsey }
        end
      end
    end

    context 'with reporter' do
      let!(:build) { create(:ee_ci_build, :dependency_scanning, pipeline: pipeline) }

      before do
        project.add_reporter(current_user)
        stub_licensed_features(dependency_scanning: true, license_scanning: true, security_dashboard: true)
      end

      it { is_expected.to be_falsey }
    end
  end
end
