# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceLimit do
  it { is_expected.to belong_to(:namespace) }

  describe '#temporary_storage_increase_enabled?' do
    let(:namespace_limit) { build(:namespace_limit) }

    subject { namespace_limit.temporary_storage_increase_enabled? }

    context 'when date is not set' do
      it { is_expected.to eq(false) }
    end

    context 'when temporary storage increase end date is today' do
      before do
        namespace_limit.temporary_storage_increase_ends_on = Date.today
      end

      it { is_expected.to eq(true) }

      context 'when feature is disabled' do
        before do
          stub_feature_flags(temporary_storage_increase: false)
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when temporary storage increase end date is exceeded' do
      before do
        namespace_limit.temporary_storage_increase_ends_on = Date.today - 1.day
      end

      it { is_expected.to eq(false) }
    end
  end
end
