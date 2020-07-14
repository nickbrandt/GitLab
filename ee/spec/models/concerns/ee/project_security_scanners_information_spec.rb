# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::EE::ProjectSecurityScannersInformation do
  let(:project) { create(:project, :repository) }
  let(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit.id, ref: project.default_branch) }

  before do
    create(:ci_build, :sast, pipeline: pipeline, status: 'success')
    create(:ci_build, :dast, pipeline: pipeline, status: 'success')
    create(:ci_build, :secret_detection, pipeline: pipeline, status: 'pending')
  end

  describe '#available_scanners' do
    before do
      allow(project).to receive(:feature_available?) { false }
      allow(project).to receive(:feature_available?).with(:sast) { true }
      allow(project).to receive(:feature_available?).with(:dast) { true }
    end

    it 'returns a list of all scanners available for the project' do
      expect(project.available_scanners).to match(%w(SAST DAST))
    end
  end

  describe '#enabled_scanners' do
    context 'when auto_devops is enabled' do
      before do
        allow_any_instance_of(Ci::Pipeline).to receive(:auto_devops_source?) { true }
      end

      it 'returns a list of all scanners enabled for the project' do
        expect(project.enabled_scanners).to match(%w(SAST DAST DEPENDENCY_SCANNING CONTAINER_SCANNING SECRET_DETECTION))
      end
    end

    context 'when auto_devops is disabled' do
      before do
        allow_any_instance_of(Ci::Pipeline).to receive(:auto_devops_source?) { false }
      end

      it 'returns a list of all scanners enabled for the project' do
        expect(project.enabled_scanners).to match(%w(SECRET_DETECTION DAST SAST))
      end
    end
  end

  describe '#scanners_run_by_last_pipeline' do
    it 'returns a list of all scanners which were run successfully in the latest pipeline' do
      expect(project.scanners_run_in_last_pipeline).to match(%w(DAST SAST))
    end
  end
end
