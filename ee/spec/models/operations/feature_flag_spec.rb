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

  describe '.for_environment' do
    subject { described_class.for_environment(environment_name) }

    before do
      stub_feature_flags(feature_flags_environment_scope: true)
    end

    context 'when feature flag is off on production' do
      before do
        feature_flag = create(:operations_feature_flag)
        create_scope(feature_flag, '*', true)
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
        feature_flag = create(:operations_feature_flag)
        create_scope(feature_flag, '*', false)
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
      let!(:feature_flag_1) { create(:operations_feature_flag) }
      let!(:feature_flag_2) { create(:operations_feature_flag) }

      before do
        create_scope(feature_flag_1, '*', true)
        create_scope(feature_flag_1, 'production', false)
        create_scope(feature_flag_2, '*', true)
      end

      context 'when environment is production' do
        let(:environment_name) { 'production' }

        it 'returns multiple actual active values' do
          expect(subject.ordered.map(&:active)).to eq([false, true])
        end
      end
    end
  end
end
