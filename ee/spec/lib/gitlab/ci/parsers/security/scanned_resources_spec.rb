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

  describe '#scanned_resources_for_csv' do
    subject { parser.scanned_resources_for_csv(scanned_resources) }

    context 'when there are scanned resources' do
      let(:scanned_resources) do
        [
          { "method" => "GET", "type" => "url", "url" => "http://railsgoat:3001" },
          { "method" => "GET", "type" => "url", "url" => "http://railsgoat:3001/" },
          { "method" => "GET", "type" => "url", "url" => "http://railsgoat:3001/login?foo=bar" },
          { "method" => "POST", "type" => "url", "url" => "http://railsgoat:3001/users" }
        ]
      end

      it 'converts the hash to OpenStructs', :aggregate_failures do
        expect(subject.length).to eq(4)
        resource = subject[2]
        expect(resource.request_method).to eq('GET')
        expect(resource.scheme).to eq('http')
        expect(resource.host).to eq('railsgoat')
        expect(resource.port).to eq(3001)
        expect(resource.path).to eq('/login')
        expect(resource.query_string).to eq('foo=bar')
      end
    end

    context 'when there is an invalid URL' do
      let(:scanned_resources) do
        [
          { "method" => "GET", "type" => "url", "url" => "http://railsgoat:3001" },
          { "method" => "GET", "type" => "url", "url" => "notaURL" },
          { "method" => "GET", "type" => "url", "url" => "" },
          { "method" => "GET", "type" => "url", "url" => nil },
          { "method" => "GET", "type" => "url", "url" => "http://railsgoat:3001/login?foo=bar" }
        ]
      end

      it 'returns a blank object with full URL string', :aggregate_failures do
        expect(subject.length).to eq(5)

        invalid_url = subject[1]
        expect(invalid_url.request_method).to eq('GET')
        expect(invalid_url.scheme).to be_nil
        expect(invalid_url.raw_url).to eq('notaURL')

        blank_url = subject[2]
        expect(blank_url.request_method).to eq('GET')
        expect(blank_url.scheme).to be_nil
        expect(blank_url.raw_url).to eq('')

        nil_url = subject[3]
        expect(nil_url.request_method).to eq('GET')
        expect(nil_url.scheme).to be_nil
        expect(nil_url.raw_url).to be_nil
      end
    end
  end
end
