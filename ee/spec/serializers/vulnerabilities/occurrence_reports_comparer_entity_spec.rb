# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::OccurrenceReportsComparerEntity do
  describe 'container scanning report comparison' do
    set(:user) { create(:user) }

    let(:base_report) { create_list(:vulnerabilities_occurrence, 2) }
    let(:head_report) { create_list(:vulnerabilities_occurrence, 1) }

    let(:comparer) { Gitlab::Ci::Reports::Security::VulnerabilityReportsComparer.new(base_report, head_report) }

    let(:request) { double('request') }

    let(:entity) { described_class.new(comparer, request: request) }

    before do
      stub_licensed_features(container_scanning: true)
    end

    describe '#as_json' do
      subject { entity.as_json }

      before do
        allow(request).to receive(:current_user).and_return(user)
      end

      it 'contains the added existing and fixed vulnerabilities for container scanning' do
        expect(subject.keys).to match_array([:added, :existing, :fixed])
      end
    end
  end
end
