# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::Security::Reports do
  let(:security_reports) { described_class.new }

  describe '#get_report' do
    subject { security_reports.get_report(report_type) }

    context 'when report type is sast' do
      let(:report_type) { 'sast' }

      it { expect(subject.type).to eq('sast') }

      it 'initializes a new report and returns it' do
        expect(Gitlab::Ci::Reports::Security::Report).to receive(:new)
          .with('sast').and_call_original

        is_expected.to be_a(Gitlab::Ci::Reports::Security::Report)
      end

      context 'when report type is already allocated' do
        before do
          subject
        end

        it 'does not initialize a new report' do
          expect(Gitlab::Ci::Reports::Security::Report).not_to receive(:new)

          is_expected.to be_a(Gitlab::Ci::Reports::Security::Report)
        end
      end
    end
  end
end
