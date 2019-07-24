# frozen_string_literal: true

require 'spec_helper'

describe ProjectCiCdSetting do
  describe '#merge_pipelines_enabled?' do
    subject { project.merge_pipelines_enabled? }

    let(:project) { create(:project) }
    let(:merge_pipelines_enabled) { true }

    before do
      project.merge_pipelines_enabled = merge_pipelines_enabled
    end

    context 'when Merge pipelines (EEP) is available' do
      before do
        stub_licensed_features(merge_pipelines: true)
      end

      it { is_expected.to be_truthy }

      context 'when project setting is disabled' do
        let(:merge_pipelines_enabled) { false }

        it { is_expected.to be_falsy }
      end
    end

    context 'when Merge pipelines (EEP) is unavailable' do
      before do
        stub_licensed_features(merge_pipelines: false)
      end

      it { is_expected.to be_falsy }

      context 'when project setting is disabled' do
        let(:merge_pipelines_enabled) { false }

        it { is_expected.to be_falsy }
      end
    end
  end

  describe '#merge_trains_enabled?' do
    subject { project.merge_trains_enabled? }

    let(:project) { create(:project) }

    context 'when Merge trains (EEP) is available' do
      before do
        stub_licensed_features(merge_pipelines: true, merge_trains: true)
        project.merge_pipelines_enabled = true
      end

      it { is_expected.to be_truthy }
    end

    context 'when Merge trains (EEP) is unavailable' do
      before do
        stub_licensed_features(merge_trains: false)
      end

      it { is_expected.to be_falsy }
    end
  end
end
