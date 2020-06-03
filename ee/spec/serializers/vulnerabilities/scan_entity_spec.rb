# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::ScanEntity do
  let(:scan) { build(:security_scan, scanned_resources_count: 10) }
  let(:request) { double('request') }

  let(:entity) do
    described_class.represent(scan, request: request)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains required fields' do
      expect(subject).to include(:scanned_resources_count)
      expect(subject).to include(:job_path)
    end

    describe 'job_path' do
      it 'returns path to the job log' do
        project = scan.build.project
        expect(subject[:job_path]).to eq("/#{project.namespace.path}/#{project.path}/-/jobs/#{scan.build.id}")
      end
    end

    describe 'scanned_resources_count' do
      context 'is nil' do
        let(:scan) { build(:security_scan, scanned_resources_count: nil) }

        it 'shows a count of 0' do
          expect(subject[:scanned_resources_count]).to be(0)
        end
      end

      context 'has a value' do
        it 'shows the count' do
          expect(subject[:scanned_resources_count]).to be(10)
        end
      end
    end
  end
end
