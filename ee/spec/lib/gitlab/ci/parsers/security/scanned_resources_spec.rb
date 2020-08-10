# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Security::ScannedResources do
  let(:parser) { described_class.new }

  describe '#scanned_resources_count' do
    subject { parser.scanned_resources_count(artifact) }

    context 'there are scanned resources' do
      let(:artifact) { create(:ee_ci_job_artifact, :dast) }

      it { is_expected.to be(6) }
    end

    context 'the scan key is missing' do
      let(:artifact) { create(:ee_ci_job_artifact, :dast_missing_scan_field) }

      it { is_expected.to be(0) }
    end

    context 'the scanned_resources key is missing' do
      let(:artifact) { create(:ee_ci_job_artifact, :dast_missing_scanned_resources_field) }

      it { is_expected.to be(0) }
    end

    context 'the json is invalid' do
      let(:artifact) { create(:ee_ci_job_artifact, :dast_with_corrupted_data) }

      it { is_expected.to be(0) }
    end
  end
end
