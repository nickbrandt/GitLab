# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::TrialHelper do
  using RSpec::Parameterized::TableSyntax

  describe '#show_trial_errors?' do
    shared_examples 'shows errors based on trial generation result' do
      where(:trial_result, :expected_result) do
        nil                | nil
        { success: true }  | false
        { success: false } | true
      end

      with_them do
        it 'show errors when trial generation was unsuccessful' do
          expect(helper.show_trial_errors?(namespace, trial_result)).to eq(expected_result)
        end
      end
    end

    context 'when namespace is nil' do
      let(:namespace) { nil }

      it_behaves_like 'shows errors based on trial generation result'
    end

    context 'when namespace is valid' do
      let(:namespace) { build(:namespace) }

      it_behaves_like 'shows errors based on trial generation result'
    end

    context 'when namespace is invalid' do
      let(:namespace) { build(:namespace, name: 'admin') }

      where(:trial_result, :expected_result) do
        nil                | true
        { success: true }  | true
        { success: false } | true
      end

      with_them do
        it 'show errors regardless of trial generation result' do
          expect(helper.show_trial_errors?(namespace, trial_result)).to eq(expected_result)
        end
      end
    end
  end
end
