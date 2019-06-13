# frozen_string_literal: true

require 'spec_helper'

describe DependencyEntity do
  describe '#as_json' do
    let(:dependency) do
      {
        name:     'nokogiri',
        packager: 'Ruby (Bundler)',
        version:  '1.8.0',
        location: {
          blob_path: '/some_project/path/Gemfile.lock',
          path:      'Gemfile.lock'
        }
      }
    end

    subject { described_class.represent(dependency).as_json }

    it { is_expected.to eq(dependency) }
  end
end
