# frozen_string_literal: true

require 'spec_helper'

describe Ci::GroupVariable do
  subject { build(:ci_group_variable) }

  it_behaves_like "CI variable"

  it { is_expected.to include_module(Presentable) }
  it { is_expected.to include_module(Ci::Maskable) }

  context 'ci_group_variable_environment_scope is enabled' do
    before do
      stub_feature_flags(ci_group_variable_environment_scope: { enabled: true, thing: subject.group })
    end

    it { is_expected.to validate_uniqueness_of(:key).scoped_to(:group_id, :environment_scope).with_message(/\(\w+\) has already been taken/) }
  end

  context 'ci_group_variable_environment_scope is disabled' do
    before do
      stub_feature_flags(ci_group_variable_environment_scope: { enabled: false, thing: subject.group })
    end

    it { is_expected.to validate_uniqueness_of(:key).scoped_to(:group_id).with_message(/\(\w+\) has already been taken/) }
  end

  describe '.unprotected' do
    subject { described_class.unprotected }

    context 'when variable is protected' do
      before do
        create(:ci_group_variable, :protected)
      end

      it 'returns nothing' do
        is_expected.to be_empty
      end
    end

    context 'when variable is not protected' do
      let(:variable) { create(:ci_group_variable, protected: false) }

      it 'returns the variable' do
        is_expected.to contain_exactly(variable)
      end
    end
  end
end
