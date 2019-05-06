# frozen_string_literal: true
require 'spec_helper'

describe 'Automated License Installation' do
  subject { load Rails.root.join('ee', 'db', 'fixtures', 'production', '010_license.rb') }

  it 'works when no license to be installed' do
    expect { subject }.not_to raise_error
  end

  context 'when GITLAB_LICENSE_FILE env variable is set' do
    let(:license_path) { 'arbitrary_file_name' }

    before do
      stub_env('GITLAB_LICENSE_FILE', license_path)
    end

    it 'fails when the file does not exist' do
      license_file = double('Pathname', exist?: false)
      allow(Pathname).to receive(:new).and_call_original
      expect(Pathname).to receive(:new).with(license_path).and_return(license_file)
      expect { subject }.to raise_error(RuntimeError, "License File Missing")
    end

    context 'when the file does exist' do
      before do
        license_file = double('Pathname', exist?: true, read: license_file_contents)
        allow(Pathname).to receive(:new).and_call_original
        expect(Pathname).to receive(:new).with(license_path).and_return(license_file)
      end

      context 'and contains a valid license' do
        let(:license_file_contents) { 'valid contents' }

        it 'succeeds in adding the license' do
          license = double('License', save: true)
          expect(License).to receive(:new).with(data: license_file_contents).and_return(license)

          expect { subject }.not_to raise_error
        end
      end

      context 'but does not contain a valid license' do
        let(:license_file_contents) { 'invalid contents' }

        it 'fails to add the license' do
          license = double('License', save: false)
          expect(License).to receive(:new).with(data: license_file_contents).and_return(license)

          expect { subject }.to raise_error(RuntimeError, "License Invalid")
        end
      end
    end
  end
end
