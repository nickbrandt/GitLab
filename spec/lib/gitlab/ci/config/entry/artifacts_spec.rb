# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Artifacts do
  let(:entry) { described_class.new(config) }
  let(:class_name) { described_class.name.demodulize.underscore }

  describe 'validations' do
    it_behaves_like 'archivable validations'

    context 'when valid' do
      context "with 'archives' keyword" do
        let(:config) { { paths: %w[public/], archives: [{ name: 'hello', path: 'path/file.txt' }] } }

        it 'returns valid entry' do
          expect(entry.value).to eq config
          expect(entry).to be_valid
        end
      end

      context "with 'reports' keyword" do
        let(:config) { { paths: %w[public/], reports: { junit: 'junit.xml' } } }

        it 'returns valid entry' do
          expect(entry.value).to eq config
          expect(entry).to be_valid
        end
      end
    end

    context 'when invalid' do
      context "with 'archives' keyword" do
        let(:config) { { paths: %w[public/], archives: { name: 'hello', path: 'path/file.txt' } } }

        it 'reports error' do
          expect(entry.errors)
            .to include 'artifacts archives should be a array'
        end
      end

      context "with 'reports' keyword" do
        let(:config) { { paths: %w[public/], reports: 'junit' } }

        it 'reports error' do
          expect(entry.errors)
            .to include 'artifacts reports should be a hash'
        end
      end
    end
  end

  describe '#compose!' do
    let(:config) { { reports: {}, paths: %w[public/], archives: [{ name: 'hello', path: 'path/file.txt' }] } }

    it 'composes archives' do
      entry.compose!

      expect(entry[:archives]).to be_a(Gitlab::Config::Entry::ComposableArray)
    end

    it 'composes reports' do
      entry.compose!

      expect(entry[:reports]).to be_a(Gitlab::Ci::Config::Entry::Reports)
    end
  end
end
