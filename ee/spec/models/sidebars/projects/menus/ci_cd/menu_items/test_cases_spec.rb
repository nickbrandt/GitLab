# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::CiCd::MenuItems::TestCases do
  let(:project) { build(:project) }
  let(:user) { project.owner }
  let(:context) { Sidebars::Projects::Context.new(current_user: user, container: project) }

  subject { described_class.new(context) }

  describe '#render?' do
    before do
      stub_licensed_features(quality_management: license_feature_status)
    end

    context 'when project has the licensed feature' do
      let(:license_feature_status) { true }

      context 'when user can read issues' do
        it 'returns true' do
          expect(subject.render?).to eq true
        end
      end

      context 'when user cannot read issues' do
        let(:user) { nil }

        it 'returns false' do
          expect(subject.render?).to eq false
        end
      end
    end

    context 'when project does not have the licensed feature' do
      let(:license_feature_status) { false }

      it 'returns false' do
        expect(subject.render?).to eq false
      end
    end
  end
end
