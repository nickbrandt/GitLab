# frozen_string_literal: true

require 'spec_helper'

describe EE::TrialHelper do
  using RSpec::Parameterized::TableSyntax

  describe '#show_trial_errors?' do
    where(:namespace, :trial_result, :expected_result) do
      nil                              | { success: true }  | false
      nil                              | nil                | nil
      build(:namespace)                | nil                | nil
      build(:namespace)                | { success: true }  | false
      build(:namespace, name: 'admin') | { success: true }  | true
      nil                              | { success: false } | true
      build(:namespace)                | { success: false } | true
    end

    with_them do
      it 'show errors when Namespace is invalid or Trial generation was unsuccessful' do
        expect(helper.show_trial_errors?(namespace, trial_result)).to eq(expected_result)
      end
    end
  end
end
