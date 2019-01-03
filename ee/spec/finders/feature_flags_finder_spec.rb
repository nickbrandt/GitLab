# frozen_string_literal: true

require 'spec_helper'

describe FeatureFlagsFinder do
  let(:finder) { described_class.new(project, user, params) }
  let(:project) { create(:project) }
  let(:user) { developer }
  let(:developer) { create(:user) }
  let(:reporter) { create(:user) }
  let(:params) { {} }

  before do
    project.add_developer(developer)
    project.add_reporter(reporter)

    stub_licensed_features(feature_flags: true)
  end

  describe '#execute' do
    subject { finder.execute }

    let!(:feature_flag_1) { create(:operations_feature_flag, name: 'flag-a', project: project) }
    let!(:feature_flag_2) { create(:operations_feature_flag, name: 'flag-b', project: project) }

    it 'returns feature flags ordered by name' do
      is_expected.to eq([feature_flag_1, feature_flag_2])
    end

    context 'when user is a reporter' do
      let(:user) { reporter }

      it 'returns an empty list' do
        is_expected.to be_empty
      end
    end

    context 'when scope is given' do
      let!(:feature_flag_1) { create(:operations_feature_flag, project: project, active: true) }
      let!(:feature_flag_2) { create(:operations_feature_flag, project: project, active: false) }

      context 'when scope is enabled' do
        let(:params) { { scope: 'enabled' } }

        it 'returns active feature flag' do
          is_expected.to eq([feature_flag_1])
        end
      end

      context 'when scope is disabled' do
        let(:params) { { scope: 'disabled' } }

        it 'returns inactive feature flag' do
          is_expected.to eq([feature_flag_2])
        end
      end
    end
  end
end
