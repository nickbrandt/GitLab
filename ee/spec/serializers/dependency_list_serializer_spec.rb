# frozen_string_literal: true

require 'spec_helper'

describe DependencyListSerializer do
  let(:build) { create(:ee_ci_build, :success) }
  set(:project) { create(:project, :repository, :private) }
  set(:user) { create(:user) }

  let(:serializer) do
    described_class.new(project: project, user: user).represent(dependencies, build: build)
  end

  let(:dependencies) do
    [{
       name:     'nokogiri',
       packager: 'Ruby (Bundler)',
       version:  '1.8.0',
       location: {
         blob_path: '/some_project/path/Gemfile.lock',
         path:      'Gemfile.lock'
       },
       vulnerabilities:
         [{
            name:     'XSS',
            severity: 'low'
          }]
     }]
  end

  before do
    stub_licensed_features(security_dashboard: true)
    project.add_developer(user)
  end

  describe "#to_json" do
    subject { serializer.to_json }

    it 'matches the schema' do
      is_expected.to match_schema('dependency_list', dir: 'ee')
    end
  end
end
