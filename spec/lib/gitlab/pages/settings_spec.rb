# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pages::Settings do
  describe '#path' do
    subject { described_class.new(settings).path }

    let(:settings) { double(path: 'the path') }

    it { is_expected.to eq('the path') }

    context 'when running under a web server outside of test mode' do
      before do
        allow(::Gitlab::Runtime).to receive(:test_suite?).and_return(false)
        allow(::Gitlab::Runtime).to receive(:web_server?).and_return(true)
      end

      it 'raises a DiskAccessDenied exception' do
        expect { subject }.to raise_error(described_class::DiskAccessDenied)
      end
    end
  end

  describe '.build_path_for' do
    subject(:build_path) { described_class.build_path_for(path_value) }

    context 'when path_value is false' do
      let(:path_value) { false }

      it 'returns false' do
        expect(build_path).to be_falsey
      end
    end

    context 'when path value is actual false string' do
      let(:path_value) { 'false' }

      it 'returns path with false as a directory' do
        expect(build_path).to eq(Settings.absolute(path_value))
      end
    end

    context 'when path value is nil' do
      let(:path_value) { nil }

      it 'returns the default path' do
        expect(build_path).to eq(Settings.absolute(File.join(Settings.shared['path'], "pages")))
      end
    end
  end
end
