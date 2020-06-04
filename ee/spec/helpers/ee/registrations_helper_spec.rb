# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::RegistrationsHelper do
  using RSpec::Parameterized::TableSyntax

  describe '#in_subscription_flow?' do
    where(:user_return_to_path, :expected_result) do
      '/-/subscriptions/new?plan_id=bronze_plan' | true
      '/foo'                                     | false
      nil                                        | false
    end

    with_them do
      it 'returns the expected_result' do
        allow(helper).to receive(:session).and_return('user_return_to' => user_return_to_path)

        expect(helper.in_subscription_flow?).to eq(expected_result)
      end
    end
  end

  describe '#in_trial_flow?' do
    where(:user_return_to_path, :expected_result) do
      '/-/trials/new?glm_content=free-trial&glm_source=about.gitlab.com' | true
      '/foo'                                                             | false
      nil                                                                | false
    end

    with_them do
      it 'returns the expected_result' do
        allow(helper).to receive(:session).and_return('user_return_to' => user_return_to_path)

        expect(helper.in_trial_flow?).to eq(expected_result)
      end
    end
  end

  describe '#in_invitation_flow?' do
    where(:user_return_to_path, :expected_result) do
      '/-/invites/xxx' | true
      '/invites/xxx'   | false
      '/foo'           | false
      nil              | nil
    end

    with_them do
      it 'returns the expected_result' do
        allow(helper).to receive(:session).and_return('user_return_to' => user_return_to_path)

        expect(helper.in_invitation_flow?).to eq(expected_result)
      end
    end
  end
end
