# frozen_string_literal: true
require 'spec_helper'

describe SystemCheck::Geo::HttpConnectionCheck do
  describe 'skip?' do
    it 'skips when Geo is disabled' do
      allow(Gitlab::Geo).to receive(:enabled?) { false }

      expect(subject.skip?).to be_truthy
      expect(subject.skip_reason).to eq('Geo is not enabled')
    end

    it 'skips when Geo is enabled but its a primary node' do
      allow(Gitlab::Geo).to receive(:enabled?) { true }
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      expect(subject.skip?).to be_truthy
      expect(subject.skip_reason).to eq('not a secondary node')
    end
  end
end
