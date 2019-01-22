require 'spec_helper'

describe Operations::FeatureFlag do
  include FeatureFlagHelpers

  subject { create(:operations_feature_flag) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:scopes) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }
  end

  describe '.enabled' do
    subject { described_class.enabled }

    context 'when the feature flag has an active scope' do
      let!(:feature_flag) { create(:operations_feature_flag, active: true) }

      it 'returns the flag' do
        is_expected.to eq([feature_flag])
      end
    end

    context 'when the feature flag does not have an active scope' do
      let!(:feature_flag) { create(:operations_feature_flag, active: false) }

      it 'does not return the flag' do
        is_expected.to be_empty
      end
    end
  end

  describe '.disabled' do
    subject { described_class.disabled }

    context 'when the feature flag has an active scope' do
      let!(:feature_flag) { create(:operations_feature_flag, active: true) }

      it 'does not return the flag' do
        is_expected.to be_empty
      end
    end

    context 'when the feature flag does not have an active scope' do
      let!(:feature_flag) { create(:operations_feature_flag, active: false) }

      it 'returns the flag' do
        is_expected.to eq([feature_flag])
      end
    end
  end

  describe '.for_environment' do
    subject { described_class.for_environment(environment_name) }

    before do
      stub_feature_flags(feature_flags_environment_scope: true)
    end

    context 'when feature flag is off on production' do
      before do
        feature_flag = create(:operations_feature_flag, active: true)
        create_scope(feature_flag, 'production', false)
      end

      context 'when environment is production' do
        let(:environment_name) { 'production' }

        it 'returns actual active value' do
          expect(subject.first.active).to be_falsy
        end
      end

      context 'when environment is staging' do
        let(:environment_name) { 'staging' }

        it 'returns actual active value' do
          expect(subject.first.active).to be_truthy
        end
      end
    end

    context 'when feature flag is default disabled but enabled for review apps' do
      before do
        feature_flag = create(:operations_feature_flag, active: false)
        create_scope(feature_flag, 'review/*', true)
      end

      context 'when environment is review app' do
        let(:environment_name) { 'review/patch-1' }

        it 'returns actual active value' do
          expect(subject.first.active).to be_truthy
        end
      end

      context 'when environment is production' do
        let(:environment_name) { 'production' }

        it 'returns actual active value' do
          expect(subject.first.active).to be_falsy
        end
      end
    end

    context 'when there are two flags' do
      let!(:feature_flag_1) { create(:operations_feature_flag, active: true) }
      let!(:feature_flag_2) { create(:operations_feature_flag, active: true) }

      before do
        create_scope(feature_flag_1, 'production', false)
      end

      context 'when environment is production' do
        let(:environment_name) { 'production' }

        it 'returns multiple actual active values' do
          expect(subject.ordered.map(&:active)).to eq([false, true])
        end
      end
    end
  end

  describe '.for_list' do
    subject { described_class.for_list }

    before do
      stub_feature_flags(feature_flags_environment_scope: true)
    end

    context 'when all scopes are active' do
      let!(:feature_flag) { create(:operations_feature_flag, active: true) }
      let!(:scope) { create_scope(feature_flag, 'production', true) }

      it 'returns virtual active value' do
        expect(subject.first.active).to be_truthy
      end
    end

    context 'when all scopes are inactive' do
      let!(:feature_flag) { create(:operations_feature_flag, active: false) }
      let!(:scope) { create_scope(feature_flag, 'production', false) }

      it 'returns virtual active value' do
        expect(subject.first.active).to be_falsy
      end
    end

    context 'when one scopes is active' do
      let!(:feature_flag) { create(:operations_feature_flag, active: false) }
      let!(:scope) { create_scope(feature_flag, 'production', true) }

      it 'returns virtual active value' do
        expect(subject.first.active).to be_truthy
      end
    end
  end
end
