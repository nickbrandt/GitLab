# frozen_string_literal: true

require 'spec_helper'

describe StoreSecurityReportsWorker do
  describe '#perform' do
    let(:pipeline) { create(:ci_pipeline, ref: 'master') }
    let(:project) { pipeline.project }

    before do
      allow(Ci::Pipeline).to receive(:find).with(pipeline.id) { pipeline }
    end

    context 'when all conditions are met' do
      before do
        stub_licensed_features(sast: true)
        stub_feature_flags(store_security_reports: true)
      end

      it 'executes StoreReportsService for given pipeline' do
        expect(Security::StoreReportsService).to receive(:new)
          .with(pipeline).once.and_call_original

        described_class.new.perform(pipeline.id)
      end
    end

    context "when security reports feature is not available" do
      let(:default_branch) { pipeline.ref }

      it 'does not execute StoreReportsService' do
        expect(Security::StoreReportsService).not_to receive(:new)

        described_class.new.perform(pipeline.id)
      end
    end

    context "when store security reports feature is not enabled" do
      let(:default_branch) { pipeline.ref }

      before do
        stub_licensed_features(sast: true)
        stub_feature_flags(store_security_reports: false)
      end

      it 'does not execute StoreReportsService' do
        expect(Security::StoreReportsService).not_to receive(:new)

        described_class.new.perform(pipeline.id)
      end
    end
  end
end
