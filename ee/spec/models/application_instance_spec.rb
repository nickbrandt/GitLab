# frozen_string_literal: true

require 'spec_helper'

describe ApplicationInstance do
  it_behaves_like Vulnerable do
    let(:vulnerable) { described_class.new }
  end

  describe '#all_pipelines' do
    it 'returns all CI pipelines for the instance' do
      allow(::Ci::Pipeline).to receive(:all)

      described_class.new.all_pipelines

      expect(::Ci::Pipeline).to have_received(:all)
    end
  end

  describe '#feature_available?' do
    subject { described_class.new.feature_available?(:security_dashboard) }

    context "when the feature is available for the instance's license" do
      before do
        stub_licensed_features(security_dashboard: true)
      end

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context "when the feature is not available for the instance's license" do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'returns false' do
        is_expected.to be_falsy
      end
    end
  end
end
