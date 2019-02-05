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

    context 'when environment scope of a default scope is updated' do
      let!(:feature_flag) { create(:operations_feature_flag) }
      let!(:default_scope) { feature_flag.default_scope }

      it 'keeps default scope intact' do
        default_scope.update(environment_scope: 'review/*')

        expect(default_scope.errors[:environment_scope])
          .to include("cannot be changed from default scope")
      end
    end

    context 'when a default scope is destroyed' do
      let!(:feature_flag) { create(:operations_feature_flag) }
      let!(:default_scope) { feature_flag.default_scope }

      it 'prevents from destroying the default scope' do
        expect { default_scope.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
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
        is_expected.to include(feature_flag_scope)
      end
    end

    context 'when scope is inactive' do
      let(:active) { false }

      it 'returns an empty array' do
        is_expected.not_to include(feature_flag_scope)
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
        is_expected.not_to include(feature_flag_scope)
      end
    end

    context 'when scope is inactive' do
      let(:active) { false }

      it 'returns the scope' do
        is_expected.to include(feature_flag_scope)
      end
    end
  end
end
