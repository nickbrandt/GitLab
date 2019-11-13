# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Sourcegraph do
  let_it_be(:user) { create(:user) }
  let(:feature) { :sourcegraph }

  describe '.feature_conditional?' do
    subject { described_class.feature_conditional? }

    context 'when feature is enabled globally' do
      it 'returns false' do
        Feature.enable(feature)

        is_expected.to be_falsey
      end
    end

    context 'when feature is enabled only to a resource' do
      it 'returns true' do
        Feature.enable(feature, user)

        is_expected.to be_truthy
      end
    end
  end

  describe '.feature_available?' do
    subject { described_class.feature_available? }

    context 'when feature is enabled globally' do
      it 'returns true' do
        Feature.enable(feature)

        is_expected.to be_truthy
      end
    end

    context 'when feature is enabled only to a resource' do
      it 'returns true' do
        Feature.enable(feature, user)

        is_expected.to be_truthy
      end
    end
  end

  describe '.feature_enabled?' do
    let_it_be(:other_user) { create(:user) }
    let(:current_user) { nil }

    subject { described_class.feature_enabled?(current_user) }

    context 'when feature is enabled globally' do
      it 'returns true' do
        Feature.enable(feature)

        is_expected.to be_truthy
      end
    end

    context 'when feature is enabled only to a resource' do
      context 'for the same resource' do
        let(:current_user) { user }

        it 'returns true' do
          Feature.enable(feature, user)

          is_expected.to be_truthy
        end
      end

      context 'for a different resource' do
        let(:current_user) { other_user }

        it 'returns false' do
          Feature.enable(feature, user)

          is_expected.to be_falsey
        end
      end
    end
  end
end
