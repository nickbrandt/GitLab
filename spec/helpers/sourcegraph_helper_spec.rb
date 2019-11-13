# frozen_string_literal: true

require 'spec_helper'

describe SourcegraphHelper do
  let(:application_setting) { true }
  let(:public_only_setting) { true }
  let(:feature_conditional) { false }

  subject { helper.sourcegraph_help_message }

  before do
    allow(Gitlab::CurrentSettings).to receive(:sourcegraph_enabled).and_return(application_setting)
    allow(Gitlab::CurrentSettings).to receive(:sourcegraph_public_only).and_return(public_only_setting)
    allow(Gitlab::Sourcegraph).to receive(:feature_conditional?).and_return(feature_conditional)
  end

  context '#sourcegraph_help_message' do
    context 'when application setting sourcegraph_enabled is disabled' do
      let(:application_setting) { false }

      it { is_expected.to be_nil }
    end

    context 'when application setting sourcegraph_enabled is enabled' do
      context 'when feature is conditional' do
        let(:feature_conditional) { true }

        it do
          is_expected.to eq "This feature is experimental and has been limited to only certain projects."
        end
      end

      context 'when feature is enabled globally' do
        before do
          stub_feature_flags(sourcegraph: true)
        end

        context 'when only works with public projects' do
          it do
            is_expected.to eq "This feature is experimental and also limited to only public projects."
          end
        end

        context 'when it works with all projects' do
          let(:public_only_setting) { false }

          it do
            is_expected.to eq "This feature is experimental."
          end
        end
      end
    end
  end
end
