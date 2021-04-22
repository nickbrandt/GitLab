# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::CiCd::MenuItems::Artifacts do
  let(:project) { build(:project) }
  let(:user) { project.owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  subject { described_class.new(context) }

  describe '#render?' do
    context 'when feature flag :artifacts_management_page is enabled' do
      it 'returns true' do
        stub_feature_flags(artifacts_management_page: true)

        expect(subject.render?).to eq true
      end
    end

    context 'when feature flag :artifacts_management_page is disabled' do
      it 'returns false' do
        stub_feature_flags(artifacts_management_page: false)

        expect(subject.render?).to eq false
      end
    end
  end
end
