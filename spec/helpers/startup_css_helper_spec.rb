# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StartupCssHelper do
  describe '#startup_css_filename' do
    let(:current_path_sessions_new) { false }
    let(:user_application_theme) { 'gl-blindlingly-bright' }

    before do
      allow(helper).to receive(:current_path?).with('sessions#new') { current_path_sessions_new }
      allow(helper).to receive(:user_application_theme) { user_application_theme }
    end

    context 'with no feature flag specified' do
      subject { helper.startup_css_filename }

      it 'defaults to startup-general' do
        expect(subject).to eq('startup-general')
      end

      context 'when current path is sessions#new' do
        let(:current_path_sessions_new) { true }

        it 'is startup-signin' do
          expect(subject).to eq('startup-signin')
        end
      end

      context 'when user_application_theme is gl-dark' do
        let(:user_application_theme) { 'gl-dark' }

        it 'is startup-dark' do
          expect(subject).to eq('startup-dark')
        end
      end
    end

    context 'when feature flag is specified' do
      let(:current_user) { double }
      let(:feature_flag) { :my_feature_flag }
      let(:flag_enabled) { false }

      subject { helper.startup_css_filename(feature_flag: feature_flag) }

      before do
        allow(helper).to receive(:current_user) { current_user }
        allow(Feature).to receive(:enabled?).with(feature_flag, current_user) { flag_enabled }
      end

      context 'when flag is disabled' do
        it 'has no extra suffix' do
          expect(subject).to eq('startup-general')
        end
      end

      context 'when flag is enabled' do
        let(:flag_enabled) { true }

        it 'has dasherized feature flag suffix' do
          expect(subject).to match('startup-general-my-feature-flag-on')
        end
      end
    end
  end
end
