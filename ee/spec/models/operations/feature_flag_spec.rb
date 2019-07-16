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

  describe 'Scope creation' do
    subject { described_class.new(**params) }

    let(:project) { create(:project) }

    let(:params) do
      { name: 'test', project: project, scopes_attributes: scopes_attributes }
    end

    let(:scopes_attributes) do
      [{ environment_scope: '*', active: false },
       { environment_scope: 'review/*', active: true }]
    end

    it { is_expected.to be_valid }

    context 'when the first scope is not wildcard' do
      let(:scopes_attributes) do
        [{ environment_scope: 'review/*', active: true },
         { environment_scope: '*', active: false }]
      end

      it { is_expected.not_to be_valid }
    end

    context 'when scope is empty' do
      let(:scopes_attributes) { [] }

      it 'creates a default scope' do
        subject.save

        expect(subject.scopes.first.environment_scope).to eq('*')
      end
    end
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

  describe '.for_list' do
    subject { described_class.for_list }

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
