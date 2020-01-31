# frozen_string_literal: true

require 'spec_helper'

describe EE::RegistrationsHelper do
  using RSpec::Parameterized::TableSyntax

  describe '#in_paid_signup_flow?' do
    where(:user_return_to_path, :paid_signup_flow_enabled, :expected_result) do
      '/-/subscriptions/new' | true  | true
      '/-/subscriptions/new' | false | false
      '/'                    | true  | false
      '/'                    | false | false
    end

    with_them do
      it 'returns the expected_result' do
        allow(helper).to receive(:experiment_enabled?).with(:paid_signup_flow).and_return(paid_signup_flow_enabled)
        allow(helper).to receive(:session).and_return('user_return_to' => user_return_to_path)

        expect(helper.in_paid_signup_flow?).to eq(expected_result)
      end
    end
  end
end
