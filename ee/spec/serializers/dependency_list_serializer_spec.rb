# frozen_string_literal: true

require 'spec_helper'

describe DependencyListSerializer do
  let(:serializer) { described_class.new(project: project).represent(dependencies, build: build) }
  let(:build) { create(:ee_ci_build, :success) }
  let(:project) { create(:project) }

  let(:dependencies) do
    [{
       name:     'nokogiri',
       packager: 'Ruby (Bundler)',
       version:  '1.8.0',
       location: {
         blob_path: '/some_project/path/Gemfile.lock',
         path:      'Gemfile.lock'
       }
     }]
  end

  describe "#to_json" do
    subject { serializer.to_json }

    it 'matches the schema' do
      is_expected.to match_schema('dependency_list', dir: 'ee')
    end
  end
end
