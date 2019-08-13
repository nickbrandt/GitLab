# frozen_string_literal: true

require 'spec_helper'

describe DependencyEntity do
  describe '#as_json' do
    subject { described_class.represent(dependency, request: request).as_json }

    set(:project) { create(:project, :repository, :private) }
    set(:user) { create(:user) }
    let(:request) { double('request') }
    let(:dependency) { dependency_info.merge(vulnerabilities) }

    let(:dependency_info) do
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

    let(:vulnerabilities) do
      {
        vulnerabilities:
          [{
             name:     'DDoS',
             severity: 'high'
           },
           {
             name:     'XSS vulnerability',
             severity: 'low'
           }]
      }
    end

    before do
      stub_licensed_features(security_dashboard: true)
      allow(request).to receive(:project).and_return(project)
      allow(request).to receive(:user).and_return(user)
    end

    context 'with developer' do
      before do
        project.add_developer(user)
      end

      it do
        is_expected.to eq(dependency)
      end
    end

    context 'with reporter' do
      before do
        project.add_reporter(user)
      end

      it { is_expected.to eq(dependency_info) }
    end
  end
end
