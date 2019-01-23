# frozen_string_literal: true

require 'spec_helper'

describe Operations::FeatureFlagScope do
  describe 'associations' do
    it { is_expected.to belong_to(:feature_flag) }
  end

  describe 'validations' do
    context 'when duplicate environment scope is going to be created' do
      let!(:existing_feature_flag_scope) do
        create(:operations_feature_flag_scope)
      end

      let(:new_feature_flag_scope) do
        build(:operations_feature_flag_scope,
          feature_flag: existing_feature_flag_scope.feature_flag,
          environment_scope: existing_feature_flag_scope.environment_scope)
      end

      it 'validates uniqueness of environment scope' do
        new_feature_flag_scope.save

        expect(new_feature_flag_scope.errors[:environment_scope])
          .to include("(#{existing_feature_flag_scope.environment_scope})" \
                      " has already been taken")
      end
    end
  end

  describe '.enabled' do
    subject { described_class.enabled }

    let!(:feature_flag_scope) do
      create(:operations_feature_flag_scope, active: active)
    end

    context 'when scope is active' do
      let(:active) { true }

      it 'returns the scope' do
        is_expected.to eq([feature_flag_scope])
      end
    end

    context 'when scope is inactive' do
      let(:active) { false }

      it 'returns an empty array' do
        is_expected.to be_empty
      end
    end
  end

  describe '.disabled' do
    subject { described_class.disabled }

    let!(:feature_flag_scope) do
      create(:operations_feature_flag_scope, active: active)
    end

    context 'when scope is active' do
      let(:active) { true }

      it 'returns an empty array' do
        is_expected.to be_empty
      end
    end

    context 'when scope is inactive' do
      let(:active) { false }

      it 'returns the scope' do
        is_expected.to eq([feature_flag_scope])
      end
    end
  end
end
