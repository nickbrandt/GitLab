# frozen_string_literal: true

require 'spec_helper'

describe DependencyEntity do
  describe '#as_json' do
    subject { described_class.represent(dependency, request: request).as_json }

    set(:project) { create(:project, :repository, :private) }
    set(:user) { create(:user) }
    let(:request) { double('request') }
    let(:dependency) { build(:dependency, :with_vulnerabilities) }

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
        is_expected.to eq(dependency.except(:licenses))
      end
    end

    context 'with reporter' do
      let(:dependency_info) { build(:dependency).except(:licenses) }

      before do
        project.add_reporter(user)
      end

      it { is_expected.to eq(dependency_info) }
    end
  end
end
